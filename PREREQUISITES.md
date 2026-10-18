# Kubeadm Prerequisites & System Requirements

Before running `kubeadm`, every participating machine must meet the hardware, networking, kernel, and software prerequisites detailed below.

---

## 1. Hardware Minimum Requirements

| Node Type | Minimum vCPUs | Recommended vCPUs | Minimum RAM | Recommended RAM | Storage |
|---|---|---|---|---|---|
| **Control Plane** | 2 vCPU | 4 vCPU | 2 GB | 4 GB | 20+ GB SSD |
| **Worker Node** | 1 vCPU | 2 vCPU | 1.5 GB | 2 GB | 20+ GB SSD |

> [!CAUTION]
> `kubeadm init` will fail preflight checks if the control plane has fewer than **2 vCPUs**.

### Hardware Identity Uniqueness:
Ensure all nodes have globally unique identifiers:
```bash
# Check MAC address
ip link

# Check Product UUID (must not match across cloned VMs)
sudo cat /sys/class/dmi/id/product_uuid
```

---

## 2. Operating System & Architecture

- **Operating System:** Ubuntu 22.04 LTS (Jammy) or Ubuntu 24.04 LTS (Noble)
- **Architecture:** `amd64` (x86_64) or `arm64` (aarch64)
- **Privileges:** Full root access or passwordless `sudo` privileges

---

## 3. Kernel Modules & Sysctl Settings

Load the required kernel modules:
```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

Ensure sysctl settings allow packet forwarding and bridge netfilter:
```ini
# /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
```

Verify that they are active:
```bash
sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward
```

---

## 4. Swap Configuration

Swap must be completely disabled on all nodes:
```bash
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
```
Verify swap is 0:
```bash
free -m | grep -i swap
```

---

## 5. Firewall Port Requirements

Ensure firewall rules (`ufw` or cloud security groups) permit traffic on these ports:

### Control Plane (`k8s-control-01`):
| Protocol | Port | Source | Description |
|---|---|---|---|
| TCP | `6443` | All nodes, operators | Kubernetes API Server |
| TCP | `2379-2380` | Control plane nodes | etcd client & peer sync |
| TCP | `10250` | Control plane & metrics | Kubelet API |
| TCP | `10259` | Internal localhost | kube-scheduler |
| TCP | `10257` | Internal localhost | kube-controller-manager |

### Worker Nodes:
| Protocol | Port | Source | Description |
|---|---|---|---|
| TCP | `10250` | Control plane | Kubelet API |
| TCP | `30000-32767` | Any / Load Balancers | NodePort Services |

### CNI Overlay Networking (All Nodes):
| Protocol | Port | Description |
|---|---|---|
| UDP | `4789` | Flannel / Calico VXLAN overlay encapsulation |
| TCP | `179` | Calico BGP peering (if BGP mode is chosen) |
