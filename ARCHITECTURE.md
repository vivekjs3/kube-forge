# Kubernetes Architecture & Platform Blueprint

Welcome to the architectural foundation of **kube-forge**. This document provides an infrastructure-level breakdown of Kubernetes internals, control plane vs. worker node data paths, security boundaries, and installation paradigms.

---

## 1. Global System Topology

At its core, Kubernetes is a distributed state machine backed by a consensus store (`etcd`) and coordinated through an active API gateway (`kube-apiserver`).

```
                              CLUSTERING BOUNDARY
  =============================================================================
  +-------------------------------------------------------------------------+
  |                          CONTROL PLANE NODE(S)                          |
  |                                                                         |
  |   +-------------------+    +-----------------------+                    |
  |   |   kube-scheduler  |    | kube-controller-mgr   |                    |
  |   +---------+---------+    +-----------+-----------+                    |
  |             |                          |                                |
  |             v                          v                                |
  |      +---------------+       +-------------------+                      |
  |      |               | <---> |       etcd        | (Port 2379/2380)     |
  |      | kube-apiserver|       +-------------------+                      |
  |      |  (Port 6443)  |                                                  |
  |      +-------+-------+                                                  |
  +--------------|----------------------------------------------------------+
                 |
                 | TLS / mTLS (HTTPS)
                 |
  +--------------|----------------------------------------------------------+
  |              v              WORKER NODE(S)                              |
  |   +---------------------+   +---------------------+   +---------------+ |
  |   |       kubelet       |   |     kube-proxy      |   |    CoreDNS    | |
  |   |    (Port 10250)     |   | (iptables/IPVS/eBPF)|   |   (Port 53)   | |
  |   +----------+----------+   +---------------------+   +---------------+ |
  |              |                                                          |
  |              v (gRPC via Unix Socket)                                   |
  |   +---------------------------------------------+                       |
  |   |   Container Runtime Interface (CRI)         |                       |
  |   |   (containerd / CRI-O / runc)               |                       |
  |   +----------------------+----------------------+                       |
  |                          |                                              |
  |                          v (CNI Plugin via veth/eBPF)                   |
  |   +---------------------------------------------+                       |
  |   |      Container Network Interface (CNI)      |                       |
  |   |       (Calico / Flannel / Cilium)           |                       |
  |   +---------------------------------------------+                       |
  |                                                                         |
  |   +----------------------+   +----------------------+                   |
  |   | Pod Sandbox A (veth) |   | Pod Sandbox B (veth) |                   |
  |   +----------------------+   +----------------------+                   |
  +-------------------------------------------------------------------------+
```

---

## 2. Component Internals & Communication Flows

Every Kubernetes node fulfills a distinct operational role. The table below details what each component does, why it exists, and how it communicates.

| Component | Layer | Communication | What it Does & Why it is Essential |
|---|---|---|---|
| **`etcd`** | State Store | Inbound from `kube-apiserver` (port 2379); Raft peer sync (port 2380) | High-availability, strongly consistent key-value store. It stores the cluster's entire state. Only the API server is permitted to talk to etcd directly. |
| **`kube-apiserver`** | Hub / Gateway | Inbound HTTPS 6443 from all components; Outbound to `etcd` and `kubelet` | The control plane hub. Validates and configures data for api objects (Pods, Services, ReplicationControllers). Exposes REST API. |
| **`kube-scheduler`** | Control Plane | Outbound HTTPS to `kube-apiserver` | Watches for newly created Pods without assigned nodes, computes node filtering and scoring algorithms, and writes the binding decision back to the API server. |
| **`kube-controller-manager`** | Control Plane | Outbound HTTPS to `kube-apiserver` | Runs core control loops (Node Lifecycle, Deployment, ReplicaSet, EndpointSlice, ServiceAccount). Continuously reconciles cluster current state with desired state. |
| **`cloud-controller-manager`** | Control Plane | Outbound HTTPS to API & Cloud APIs | Interfaces with cloud provider APIs (load balancers, node routing, storage volumes). Optional on pure bare-metal. |
| **`kubelet`** | Node Agent | Inbound HTTPS 10250 from API server; Outbound HTTPS 6443 to API server | The primary node agent. Watches PodSpecs via the API server, instructs the CRI to spin up/down containers, reports node and pod health. |
| **`CRI Runtime`** | Node Runtime | Inbound gRPC over Unix socket (`/run/containerd/containerd.sock`) | Implements the Container Runtime Interface. Manages container images, creates Linux namespaces, cgroups, and invokes low-level OCI runtimes (`runc`, `crun`). |
| **`CNI Plugin`** | Node Network | Executed as binary or daemonset (Calico, Flannel, Cilium) | Plugs container network interfaces into host virtual switches/bridges, configures IP addresses (IPAM), and manages pod-to-pod network routing across nodes. |
| **`kube-proxy`** | Node Routing | Outbound HTTPS to API server; writes kernel iptables / IPVS / eBPF | Reflects Kubernetes `Service` definitions on each node and handles layer 4 TCP/UDP load balancing to healthy backend Pod endpoints. |
| **`CoreDNS`** | Cluster DNS | Inbound UDP/TCP port 53 from Pods | Internal authoritative DNS server providing cluster-wide service discovery (e.g. `service.namespace.svc.cluster.local`). |

---

## 3. Communication Sequence: Pod Creation Lifecycle

Understanding how components collaborate during a deployment highlights why each element must be operational:

```
User (kubectl)     kube-apiserver        etcd          kube-scheduler    kube-controller-mgr        kubelet            CRI / CNI
     |                   |                |                  |                    |                    |                   |
     | 1. POST Deployment|                |                  |                    |                    |                   |
     |------------------>|                |                  |                    |                    |                   |
     |                   | 2. Write state |                  |                    |                    |                   |
     |                   |--------------->|                  |                    |                    |                   |
     |                   |                |                  |                    |                    |                   |
     |                   | 3. Watch: Deployment created      |                    |                    |                   |
     |                   |------------------------------------------------------->|                    |                   |
     |                   | 4. Create ReplicaSet & Pod Specs  |                    |                    |                   |
     |                   |<-------------------------------------------------------|                    |                   |
     |                   | 5. Persist Pod (nodeName="")      |                    |                    |                   |
     |                   |--------------->|                  |                    |                    |                   |
     |                   |                |                  |                    |                    |                   |
     |                   | 6. Watch: Unscheduled Pod         |                    |                    |                   |
     |                   |---------------------------------->|                    |                    |                   |
     |                   | 7. Filter & score nodes; Bind     |                    |                    |                   |
     |                   |<----------------------------------|                    |                    |                   |
     |                   | 8. Persist node assignment        |                    |                    |                   |
     |                   |--------------->|                  |                    |                    |                   |
     |                   |                |                  |                    |                    |                   |
     |                   | 9. Watch: Pod assigned to local node                   |                    |                   |
     |                   |---------------------------------------------------------------------------->|                   |
     |                   |                |                  |                    |                    | 10. RunPodSandbox |
     |                   |                |                  |                    |                    |------------------>|
     |                   |                |                  |                    |                    | 11. Setup CNI net |
     |                   |                |                  |                    |                    |------------------>|
     |                   |                |                  |                    |                    | 12. Pull & start  |
     |                   |                |                  |                    |                    |------------------>|
     |                   | 13. Pod status: Running           |                    |                    |                   |
     |                   |<----------------------------------------------------------------------------|                   |
     |                   | 14. Update etcd|                  |                    |                    |                   |
     |                   |--------------->|                  |                    |                    |                   |
```

---

## 4. Network Architecture & Address Spaces

A properly provisioned Kubernetes cluster segregates networking into three non-overlapping CIDR address spaces:

1. **Host / Node Network (Underlay):**
   - Physical or virtual LAN connecting nodes (e.g., `10.10.10.0/24`).
   - Must allow node-to-node communication across required ports.
2. **Pod Network (Overlay / Routed):**
   - Private IP space dedicated to Pods (e.g., `10.244.0.0/16` or `192.168.0.0/16`).
   - Every Pod receives its own routable IP within this subnet. Pods must be able to communicate with all other Pods on any node without NAT.
3. **Service Network (Virtual ClusterIPs):**
   - Virtual CIDR (e.g., `10.96.0.0/12`).
   - IPs exist only in kernel routing tables (iptables/IPVS/eBPF maps); no physical device or veth possesses a Service IP.

---

## 5. Security & PKI Architecture

Kubernetes is zero-trust by default. Communication between all control-plane and worker components is encrypted via Mutual TLS (mTLS).

```
                            +-----------------------------+
                            |     Cluster Root CA         |
                            |       ca.crt / ca.key       |
                            +--------------+--------------+
                                           |
                 +-------------------------+-------------------------+
                 |                         |                         |
                 v                         v                         v
     +-----------------------+ +-----------------------+ +-----------------------+
     |   API Server Certs    | |    kubelet Client     | |    etcd Peer / Client |
     |  apiserver.crt (SANs) | |    kubelet.crt/key    | |      etcd-peer.crt    |
     +-----------------------+ +-----------------------+ +-----------------------+
```

### Essential Certificates:
- **`ca.crt`**: Root Certificate Authority certifying all internal components.
- **`apiserver.crt`**: Server certificate for the API server containing DNS and IP Subject Alternative Names (SANs) for `kubernetes`, `kubernetes.default`, control plane IPs, and load balancer hostnames.
- **`apiserver-kubelet-client.crt`**: Used by the API server to authenticate when calling kubelets for log streaming, exec, and port forwarding.
- **`front-proxy-ca.crt`**: Supports aggregated API servers (e.g., Metrics Server).
- **`etcd/ca.crt`**: Dedicated CA for etcd peer-to-peer and client authentication.

---

## 6. Installation Paradigms Compared

| Paradigm | Exemplar | Pros | Cons / Trade-offs | Ideal Use Case |
|---|---|---|---|---|
| **Manual (From Scratch)** | `hardway` | Complete transparency into every binary, certificate, and systemd service. Zero magic. | High operational maintenance; manual certificate renewal; not suited for fast bootstrapping. | Education, mastery of K8s internals, bare-metal engineering. |
| **Upstream Bootstrapper** | `kubeadm` | Official CNCF standard, static pod architecture, modular, broad ecosystem support. | Manual multi-node infrastructure provisioning; requires manual CNI deployment. | Standard bare-metal production, enterprise private clouds. |
| **Packaged Distribution** | `k3s` | Single binary, negligible RAM (<512MB), embedded SQLite/etcd, rapid setup. | Non-standard storage backend options by default; modified binary packaging. | Edge devices, IoT, local lab, CI/CD runners, lightweight VMs. |
| **Hardened Enterprise** | `rke2` | CIS benchmark hardened out-of-the-box, FIPS 140-2 compliance, embedded containerd & etcd. | Heavier resource footprint than k3s; Rancher-centric conventions. | Regulated enterprise, government, security-sensitive production. |
| **Developer Sandbox** | `minikube` / `microk8s` | One-command spinup, rich addon ecosystem (dashboards, ingress, registries). | Not suitable for bare-metal multi-node production clusters. | Local developer workstations, rapid feature testing. |
| **Automated Orchestrator**| `kubespray` | Fully automated Ansible playbooks, multi-OS support, day-2 operations (scaling/upgrades). | Slow execution times; requires mastery of Ansible and inventory management. | Large bare-metal fleets, complex heterogeneous infrastructure. |
| **Immutable Linux OS** | `talos` | Minimal attack surface, no SSH/bash, declarative gRPC API, immutable filesystem. | Requires learning Talos API; cannot run arbitrary Linux debugging tools on the host. | Modern bare-metal GitOps, immutable secure infrastructure. |
