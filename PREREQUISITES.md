# RKE2 Prerequisites & System Requirements

Before deploying RKE2, nodes must satisfy the hardware, kernel, and firewall port requirements outlined below.

---

## 1. Hardware Requirements

| Role | Minimum vCPU | Recommended vCPU | Minimum RAM | Recommended RAM | Storage |
|---|---|---|---|---|---|
| **RKE2 Server** | 2 vCPU | 4 vCPU | 3.5 GB | 4 GB - 8 GB | 30+ GB SSD |
| **RKE2 Agent** | 1 vCPU | 2 vCPU | 1.5 GB | 2 GB - 4 GB | 20+ GB SSD |

*Note: RKE2 runs full etcd and bundled security controllers, requiring higher minimum RAM than K3s.*

---

## 2. Operating System & Kernel

- **Operating System:** Ubuntu 22.04 LTS (Jammy) / 24.04 LTS (Noble), RHEL 8/9, Rocky Linux 8/9.
- **Kernel Modules:**
  ```bash
  sudo modprobe overlay
  sudo modprobe br_netfilter
  ```
- **Sysctl Settings:**
  ```ini
  net.bridge.bridge-nf-call-iptables = 1
  net.ipv4.ip_forward = 1
  ```

---

## 3. Firewall Port Requirements

### RKE2 Server (`rke2-server-01`):
| Protocol | Port | Source | Description |
|---|---|---|---|
| **TCP** | `9345` | All nodes | RKE2 Supervisor API (Node join & token validation) |
| **TCP** | `6443` | All nodes & kubectl | Kubernetes API Server |
| **TCP** | `2379-2380`| Server peers | etcd client & peer sync (HA clusters) |
| **TCP** | `10250` | Server | Kubelet API |
| **UDP** | `8472` | All nodes | Canal / Flannel VXLAN overlay |
| **TCP** | `80 / 443`| External clients | NGINX Ingress Controller |

### RKE2 Agent (`rke2-agent-01`):
| Protocol | Port | Source | Description |
|---|---|---|---|
| **TCP** | `10250` | Server | Kubelet API |
| **UDP** | `8472` | All nodes | Canal VXLAN overlay |
