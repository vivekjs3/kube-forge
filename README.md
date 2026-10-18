# Kubeadm Installation Laboratory 🚀

> **Official CNCF Standard Kubernetes Bootstrap**  
> *Target Audience:* Beginners to Intermediate Platform Engineers  
> *Target OS:* Ubuntu 22.04 LTS / 24.04 LTS  
> *Target Kubernetes Version:* v1.31.x (with containerd v1.7.x / v2.0.x)

---

## 🎯 What is Kubeadm?

`kubeadm` is the official community-maintained cluster bootstrapper created by Kubernetes Special Interest Group (SIG) Cluster Lifecycle. It establishes a minimum viable, conformant Kubernetes cluster following best practices.

### Core Philosophy:
- **Separation of Concerns:** `kubeadm` only bootstraps the cluster. It does not provision your VMs, configure your network interfaces, or install your container runtime.
- **Static Pod Architecture:** Rather than running control-plane services as Linux system daemons, `kubeadm` configures the host `kubelet` to run `kube-apiserver`, `etcd`, `kube-controller-manager`, and `kube-scheduler` as **Static Pods** managed via manifests placed in `/etc/kubernetes/manifests/`.

---

## 🏗️ Laboratory Topology

```
                  Host Network: 10.10.10.0/24 (Example LAN)
                                      |
         +----------------------------+----------------------------+
         |                                                         |
         v                                                         v
+-------------------------+                               +-------------------------+
|     k8s-control-01      |                               |      k8s-worker-01      |
| IP: 10.10.10.10         |                               | IP: 10.10.10.11         |
| Role: Control Plane     |                               | Role: Worker Node       |
| 2 vCPU, 4 GB RAM        |                               | 2 vCPU, 2 GB RAM        |
+-------------------------+                               +-------------------------+
```

### IP Subnets:
- **Node Underlay Network:** `10.10.10.0/24`
- **Pod Network (CNI CIDR):** `10.244.0.0/16` (Flannel) or `192.168.0.0/16` (Calico)
- **Service Network (ClusterIP CIDR):** `10.96.0.0/12`

---

## 📋 Step-by-Step Installation Workflow

Follow the numbered scripts in `scripts/`. Every script is modular, transparent, and idempotent.

### On Control Plane (`k8s-control-01`):
```bash
# Step 1: Validate system resources, kernel, and ports
sudo ./scripts/01-prerequisites.sh

# Step 2: Configure kernel modules, sysctl, and disable swap
sudo ./scripts/02-system-config.sh

# Step 3: Install & configure containerd runtime (systemd cgroup driver)
sudo ./scripts/03-container-runtime.sh

# Step 4: Install kubeadm, kubelet, and kubectl (Kubernetes v1.31)
sudo ./scripts/04-install-kubernetes.sh

# Step 5: Initialize the control plane
sudo ./scripts/05-init-cluster.sh

# Step 6: Install Container Network Interface (CNI) (Calico / Flannel)
./scripts/06-install-cni.sh
```

### On Worker Nodes (`k8s-worker-01`, etc.):
```bash
# Run steps 1 to 4 on the worker node first:
sudo ./scripts/01-prerequisites.sh
sudo ./scripts/02-system-config.sh
sudo ./scripts/03-container-runtime.sh
sudo ./scripts/04-install-kubernetes.sh

# Step 7: Join the worker to the control plane
sudo ./scripts/07-join-workers.sh
```

### Post-Installation Cluster Validation:
```bash
# Step 8: Validate nodes, pods, CoreDNS, and run a test workload
./scripts/08-validate.sh
```

---

## 🔍 What Happens During `kubeadm init`?

1. **Preflight Checks:** Validates OS compatibility, kernel modules, port availability, and disables swap.
2. **PKI Generation:** Generates the cluster Certificate Authority (`ca.crt`) and component mTLS certificates in `/etc/kubernetes/pki/`.
3. **Kubeconfig Creation:** Writes admin and service kubeconfig files to `/etc/kubernetes/`.
4. **Static Pod Manifests:** Writes manifests for `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, and `etcd` to `/etc/kubernetes/manifests/`.
5. **Kubelet Ingestion:** The local host `kubelet` detects these manifests and instructs `containerd` to spawn the control-plane containers.
6. **RBAC & Taints:** Configures CoreDNS, kube-proxy DaemonSet, and applies the `node-role.kubernetes.io/control-plane:NoSchedule` taint to the control plane.
7. **Bootstrap Token:** Creates a temporary bootstrap token for worker nodes to join securely.

---

## 🔄 Reset & Cleanup

To cleanly wipe the cluster configuration and restore nodes:
```bash
sudo ./scripts/reset.sh
```
See [RESET.md](file:///home/vivek/k8s-proj/RESET.md) for full details.

---

## 📖 Deep Dives

- [ARCHITECTURE.md](file:///home/vivek/k8s-proj/ARCHITECTURE.md) — Kubeadm static pod architecture and data paths.
- [PREREQUISITES.md](file:///home/vivek/k8s-proj/PREREQUISITES.md) — Node hardware, OS kernel, and port requirements.
- [TROUBLESHOOTING.md](file:///home/vivek/k8s-proj/TROUBLESHOOTING.md) — Common failure modes (NotReady nodes, CNI errors, CoreDNS pending) and exact fixes.
- [docs/networking.md](file:///home/vivek/k8s-proj/docs/networking.md) — CNI plugin options and routing mechanics.
