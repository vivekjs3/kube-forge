# K3s Prerequisites & System Requirements

K3s is designed to be lightweight, but nodes must still satisfy basic Linux kernel, network port, and resource baselines.

---

## 1. Hardware Requirements

| Role | Minimum vCPU | Recommended vCPU | Minimum RAM | Recommended RAM | Storage |
|---|---|---|---|---|---|
| **K3s Server** | 1 vCPU | 2 vCPU | 512 MB | 1 GB - 2 GB | 10+ GB SSD/eMMC |
| **K3s Agent** | 1 vCPU | 1 vCPU | 256 MB | 512 MB - 1 GB | 10+ GB SSD/eMMC |

---

## 2. Operating System & Architecture

- **Operating System:** Ubuntu 22.04 LTS / 24.04 LTS, Debian 11/12, Alpine Linux, Raspberry Pi OS.
- **Architectures:** `amd64` (x86_64), `arm64` (aarch64), `armv7l`.
- **Privileges:** Root access or `sudo`.

---

## 3. Kernel Modules & Sysctl

K3s requires the standard bridge and packet forwarding sysctls:
```bash
sudo modprobe overlay
sudo modprobe br_netfilter

sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
sudo sysctl -w net.ipv4.ip_forward=1
```

*Note: Unlike upstream Kubernetes, K3s can tolerate running on machines with active swap, but disabling swap is still recommended for performance predictability.*

---

## 4. Firewall Port Matrix

### K3s Server (`k3s-server-01`):
| Protocol | Port | Source | Description |
|---|---|---|---|
| **TCP** | `6443` | All nodes & kubectl | Kubernetes API Server & Agent registration |
| **UDP** | `8472` | All nodes | Flannel VXLAN overlay encapsulation (default) |
| **TCP** | `10250` | Server | Kubelet metrics and logs |
| **TCP** | `80 / 443`| External clients | Traefik Ingress HTTP / HTTPS routers |
| **TCP** | `2379-2380`| Server peers | Required **only** if running in embedded HA etcd mode |

### K3s Agent (`k3s-agent-01`):
| Protocol | Port | Source | Description |
|---|---|---|---|
| **TCP** | `10250` | Server | Kubelet API |
| **UDP** | `8472` | All nodes | Flannel VXLAN overlay network |
