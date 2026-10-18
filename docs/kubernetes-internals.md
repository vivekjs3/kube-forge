# Kubernetes Internals Deep Dive

To administer, troubleshoot, and automate Kubernetes installations effectively, you must understand the operational lifecycle of its core binaries and data stores.

---

## 1. The Distributed Control Plane

The control plane maintains the desired state of the cluster, responds to events, and issues commands to the worker fleet.

```
+---------------------------------------------------------------------------------------+
|                                    CONTROL PLANE                                      |
|                                                                                       |
|   +-----------------------+                    +----------------------------------+   |
|   |    kube-scheduler     |                    |     kube-controller-manager      |   |
|   | Watches unscheduled   |                    | Reconciles desired vs actual     |   |
|   | Pods & binds to node  |                    | state across node/workload loops |   |
|   +-----------+-----------+                    +-----------------+----------------+   |
|               |                                                  |                    |
|               | (mTLS / HTTP REST API)                           | (mTLS)             |
|               +------------------------+-------------------------+                    |
|                                        |                                              |
|                                        v                                              |
|                         +------------------------------+                              |
|                         |        kube-apiserver        | (Port 6443)                  |
|                         | Authentication, RBAC, Schema |                              |
|                         | Validation, Admission Review |                              |
|                         +--------------+---------------+                              |
|                                        |                                              |
|                                        | (mTLS / Raft)                                |
|                                        v                                              |
|                         +------------------------------+                              |
|                         |             etcd             | (Port 2379 / 2380)           |
|                         | High-consistency KV state    |                              |
|                         +------------------------------+                              |
+---------------------------------------------------------------------------------------+
```

### A. etcd (The Source of Truth)
- **Role:** Distributed, strongly consistent key-value store using the Raft consensus algorithm.
- **Why Required:** Stores cluster specifications, runtime metadata, secrets, configmaps, and resource versions.
- **Internal Details:** All mutations in Kubernetes are stored as serialized Protobuf/JSON keys under the `/registry` prefix in etcd. Writes require a Raft quorum (`(N/2) + 1`).
- **Communication:** Only the `kube-apiserver` speaks directly with `etcd`. No other component is allowed direct access.

### B. kube-apiserver (The Cluster Central Hub)
- **Role:** Central REST API gateway, schema validator, and admission controller.
- **Why Required:** Acts as the single point of entry for all control-plane and worker requests.
- **Internal Pipeline for Requests:**
  1. **Authentication:** Validates client identity (mTLS X.509 certs, Bearer tokens, OIDC).
  2. **Authorization:** Checks permissions against RBAC (`Role`, `ClusterRole`, `ClusterRoleBinding`).
  3. **Mutating Admission:** Executes webhooks to modify resource definitions before persistence.
  4. **Object Schema Validation:** Validates API object schema adherence.
  5. **Validating Admission:** Executes final admission acceptance checks.
  6. **Persistence:** Writes validated object to `etcd`.

### C. kube-scheduler (The Placement Brain)
- **Role:** Continuously watches for newly created Pods where `spec.nodeName` is empty.
- **Why Required:** Decides which physical or virtual node should host each Pod based on resource requirements, affinity, anti-affinity, taints, and tolerations.
- **Two-Phase Algorithm:**
  1. **Filtering (Predicates):** Filters out nodes that cannot satisfy the Pod's constraints (e.g. insufficient CPU/memory, incompatible taints, missing node labels).
  2. **Scoring (Priorities):** Scores remaining candidate nodes to choose the optimal placement (e.g. least allocated resource distribution).
  3. **Binding:** Issues an HTTP POST request to `kube-apiserver` setting `spec.nodeName`.

### D. kube-controller-manager (The Continuous Reconciler)
- **Role:** Runs core control loops in a continuous loop (`Reconcile()` cycle).
- **Why Required:** Kubernetes is declarative: you define what you *want*, and controller managers bring *actual state* in alignment with *desired state*.
- **Key Sub-Controllers:**
  - **Node Controller:** Detects when nodes stop responding to heartbeats and evicts pods.
  - **Replication / Deployment Controller:** Ensures the number of running pod replicas matches the replica count in the deployment manifest.
  - **EndpointSlice Controller:** Populates EndpointSlice objects linking services to healthy pod IPs.
  - **ServiceAccount Controller:** Automatically generates default ServiceAccounts and token secrets for namespaces.

---

## 2. The Node Data Plane

Worker nodes execute actual application containers and handle network forwarding.

```
+---------------------------------------------------------------------------------------+
|                                      WORKER NODE                                      |
|                                                                                       |
|   +-------------------------------------------------------------------------------+   |
|   |                                    kubelet                                    |   |
|   | Watches API server for local PodSpecs, syncs with CRI, reports node status    |   |
|   +-------------------+---------------------------------------+-------------------+   |
|                       |                                       |                       |
|                       | (gRPC Unix Socket)                    | (CNI Execution)       |
|                       v                                       v                       |
|   +---------------------------------------+   +-----------------------------------+   |
|   |    Container Runtime (containerd)     |   |      CNI Plugin (Calico/Flannel)  |   |
|   | Image pulls, cgroups, Linux namespaces|   | Allocates veth pair, assigns IP,  |   |
|   +-------------------+-------------------+   | configures host network routes    |   |
|                       |                       +-----------------------------------+   |
|                       v                                                               |
|   +-------------------------------------------------------------------------------+   |
|   |                             Container (Pod Sandbox)                           |   |
|   +-------------------------------------------------------------------------------+   |
|                                                                                       |
|   +-------------------------------------------------------------------------------+   |
|   |                                  kube-proxy                                   |   |
|   | Programs host iptables / IPVS rules to load-balance Service ClusterIPs        |   |
|   +-------------------------------------------------------------------------------+   |
+---------------------------------------------------------------------------------------+
```

### A. kubelet (The Node Overseer)
- **Role:** Daemon running directly on the Linux host OS (via `systemd`).
- **Why Required:** Translates declarative PodSpecs into concrete container lifecycles on the local node.
- **Internal Details:**
  - Communicates with the container runtime via the Container Runtime Interface (CRI) over a Unix Domain Socket (e.g., `/run/containerd/containerd.sock`).
  - Periodically sends node status updates and pod status heartbeats to `kube-apiserver`.
  - Performs liveness and readiness probe checks.

### B. Container Runtime Interface (CRI)
- **Role:** Manages container images, storage mounts, and invokes low-level OCI runtimes (e.g. `runc`).
- **Why Required:** Decouples Kubernetes from specific container software implementations.
- **Standard Runtime:** `containerd` with `cgroupfs` or `systemd` cgroup drivers.

### C. Container Network Interface (CNI)
- **Role:** Configures container network interfaces inside newly spawned Linux network namespaces.
- **Why Required:** Provides each Pod with a unique, routable IP address and establishes overlay or flat routed networking across nodes.

### D. kube-proxy (Service Routing & Load Balancing)
- **Role:** Watches Kubernetes `Service` and `EndpointSlice` resources.
- **Why Required:** Implements the virtual `ClusterIP` network abstraction.
- **Modes:**
  - **iptables mode:** Generates Linux iptables chains using `PREROUTING` and random probability packet matching to distribute traffic across endpoints.
  - **IPVS mode:** Uses Linux kernel IP Virtual Server hash tables for high-performance L4 load balancing.
