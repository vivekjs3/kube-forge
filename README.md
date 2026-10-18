# Kubernetes The Hard Way (Manual Installation Laboratory) 🧠

> **Master Kubernetes Internals from Scratch: Raw Binaries, Systemd Units, and Manual PKI**  
> *Target Audience:* Experienced Linux Administrators, SREs, and Platform Engineers seeking complete mastery  
> *Target OS:* Ubuntu 22.04 LTS / 24.04 LTS  
> *Target Kubernetes Version:* v1.31.x / v1.30.x (Upstream Binaries)

---

## 🎯 What is Kubernetes The Hard Way?

Inspired by Kelsey Hightower's seminal guide, this laboratory strips away all bootstrapping abstractions (no `kubeadm`, no `k3s`, no `rke2`). 

You will install and configure every single Kubernetes binary by hand:
- Initialize your own **Certificate Authority (CA)** and generate individual TLS certificates for every component.
- Configure and run **etcd** directly as a native Linux `systemd` service.
- Download and run **`kube-apiserver`**, **`kube-controller-manager`**, and **`kube-scheduler`** as systemd services.
- Configure **RBAC** authorizing the API server to communicate with Kubelets.
- Download and run **`containerd`**, **`kubelet`**, and **`kube-proxy`** on worker nodes.
- Configure Pod and Service networking from the ground up.

---

## 🏗️ Laboratory Topology

```
                  Host Network: 10.10.10.0/24 (Example Subnet)
                                      |
         +----------------------------+----------------------------+
         |                                                         |
         v                                                         v
+-------------------------+                               +-------------------------+
|      k8s-control-01     |                               |       k8s-worker-01     |
| IP: 10.10.10.10         |                               | IP: 10.10.10.11         |
| Role: Control Plane     |                               | Role: Worker Node       |
| 2 vCPU, 4 GB RAM        |                               | 2 vCPU, 2 GB RAM        |
+-------------------------+                               +-------------------------+
```

### IP Subnets:
- **Node Underlay:** `10.10.10.0/24`
- **Pod Network (Per-Node Subnet):** `10.200.0.0/16` (Worker 1: `10.200.0.0/24`)
- **Service Network (ClusterIPs):** `10.32.0.0/24`

---

## 📋 Step-by-Step Installation Workflow

Follow the numbered scripts in `scripts/`:

```bash
# Step 1: Verify hardware, kernel, and install tools (cfssl, cfssljson, etc.)
sudo ./scripts/01-prerequisites.sh

# Step 2: Configure Linux kernel modules and sysctl
sudo ./scripts/02-system-config.sh

# Step 3: Generate PKI Certificate Authority and all component TLS certificates
./scripts/03-generate-pki.sh

# Step 4: Generate client and component kubeconfigs
./scripts/04-generate-kubeconfigs.sh

# Step 5: Install and start etcd cluster service
sudo ./scripts/05-install-etcd.sh

# Step 6: Install control plane binaries & start systemd services
sudo ./scripts/06-install-control-plane.sh

# Step 7: Install worker binaries (containerd, runc, CNI plugins, kubelet, kube-proxy)
sudo ./scripts/07-install-worker.sh

# Step 8: Configure host routing / CNI network bridge
sudo ./scripts/08-configure-networking.sh

# Step 9: Validate cluster health, component communication, and test workload
./scripts/09-validate.sh
```

---

## 🔍 What You Learn by Going "The Hard Way"

1. **The PKI Web:** Exactly which client certificate connects to which server certificate, what Subject Alternative Names (SANs) are required, and why certificates expire.
2. **Kubeconfig Construction:** How `kubectl` stitches together cluster endpoints, base64-encoded client certificates, and user contexts.
3. **Control Plane Decoupling:** Proves that `kube-apiserver`, `kube-controller-manager`, and `kube-scheduler` are independent processes that only coordinate via HTTP REST requests to the API server.
4. **Kubelet Independence:** How the Kubelet bootstraps itself, executes OCI runtimes via CRI sockets, and interacts with CNI plugins.

---

## 🔄 Reset & Cleanup

To stop all systemd services, remove binaries, and purge PKI certificates:
```bash
sudo ./scripts/reset.sh
```

---

## 📖 Deep Dives

- [ARCHITECTURE.md](file:///home/vivek/k8s-proj/ARCHITECTURE.md) — Systemd unit architecture and mTLS authentication graph.
- [PREREQUISITES.md](file:///home/vivek/k8s-proj/PREREQUISITES.md) — Tooling, `cfssl`, and OS requirements.
- [TROUBLESHOOTING.md](file:///home/vivek/k8s-proj/TROUBLESHOOTING.md) — Certificate errors, systemd service crashes, and routing issues.
- [docs/networking.md](file:///home/vivek/k8s-proj/docs/networking.md) — How raw Linux bridges (`cbr0`) and IP routes handle Pod communication.
