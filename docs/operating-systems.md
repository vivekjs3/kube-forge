# Operating System Preparation & Kernel Hardening

A resilient Kubernetes cluster relies heavily on host operating system configurations, kernel subsystems, and firewall rules. This guide documents the exact Linux settings required before installing any Kubernetes distribution.

---

## 1. Operating System Compatibility Matrix

| Distribution | Version | Kernel Version | Cgroup Version | Validation Status |
|---|---|---|---|---|
| **Ubuntu Server** | 22.04 LTS (Jammy) | 5.15+ / 6.5 HWE | cgroup v2 / v1 hybrid | **Primary Validated** |
| **Ubuntu Server** | 24.04 LTS (Noble) | 6.8+ | cgroup v2 default | **Primary Validated** |
| **Debian** | 12 (Bookworm) | 6.1+ | cgroup v2 default | Planned / Community |
| **Rocky / AlmaLinux**| 9.x | 5.14+ | cgroup v2 default | Planned / Community |
| **Talos Linux** | 1.8+ | Minimal custom | cgroup v2 | **Dedicated OS Branch** |

---

## 2. Kernel Modules

Kubernetes container runtimes and network bridges require specific Linux kernel modules loaded at boot:

```bash
# /etc/modules-load.d/k8s.conf
overlay
br_netfilter
```

### Why are these required?
1. **`overlay`**: Enables the OverlayFS union filesystem driver, allowing container layers (base image, application layers, writable container layer) to be merged into a unified root filesystem.
2. **`br_netfilter`**: Ensures that packets traversing host network bridges (such as virtual pod bridges) are passed to `iptables` and `netfilter` for filtering and NAT processing.

---

## 3. Sysctl Network & Bridge Tuning

Without explicit kernel forwarding and bridge configuration, pod-to-pod networking and service routing will fail silently.

```ini
# /etc/sysctl.d/99-kubernetes.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
```

### Deep Dive:
- `net.ipv4.ip_forward = 1`: Instructs the Linux kernel to act as a router. When a packet arrives with a destination IP not belonging to the host's own network cards, the kernel forwards it rather than dropping it.
- `net.bridge.bridge-nf-call-iptables = 1`: Forces bridged traffic (packets between containers on the same bridge) through the host's `iptables` rules, enabling security policies and kube-proxy DNAT.

---

## 4. Swap Configuration

Historically, Kubernetes required swap to be disabled completely:
```bash
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
```

### Why was swap disabled?
1. **Predictable Scheduling:** The Kubernetes scheduler allocates Pods based on precise CPU and physical memory guarantees (`requests` and `limits`). If memory spills over to disk swap, application latency degrades unpredictably, defeating QoS guarantees.
2. **OOM Killer Precision:** When a container exceeds its memory limit, the Linux kernel Out-Of-Memory (OOM) killer must terminate that specific container rather than allowing thrashing.
3. **Modern Status:** Kubernetes v1.28+ introduced alpha/beta support for swap on cgroup v2, but production best practice remains disabling swap on bare-metal worker nodes.

---

## 5. Cgroup Drivers: systemd vs. cgroupfs

Linux cgroups (control groups) constrain and isolate resource usage (CPU, RAM, block I/O) for containers.

> [!IMPORTANT]
> The container runtime (`containerd`) and the `kubelet` **must both use the `systemd` cgroup driver** on modern Linux systems (systemd-based).
> Using `cgroupfs` alongside systemd creates two competing resource managers, leading to node instability and unexpected pod evictions under memory pressure.

---

## 6. Firewall & Network Port Matrix

Before provisioning, ensure host firewalls (`ufw`, `firewalld`, or cloud security groups) allow the following ports:

### Control Plane Nodes
| Protocol | Port Range | Purpose | Used By |
|---|---|---|---|
| **TCP** | `6443` | Kubernetes API Server | All nodes, admins, kubectl |
| **TCP** | `2379-2380` | etcd client & peer sync | `kube-apiserver`, etcd peers |
| **TCP** | `10250` | Kubelet API | `kube-apiserver` (logs/exec) |
| **TCP** | `10259` | kube-scheduler | Internal scheduler metrics |
| **TCP** | `10257` | kube-controller-manager | Internal controller metrics |

### Worker Nodes
| Protocol | Port Range | Purpose | Used By |
|---|---|---|---|
| **TCP** | `10250` | Kubelet API | Control plane, metrics server |
| **TCP** | `30000-32767` | NodePort Services | External users/load balancers |

### CNI & Overlay Network (All Nodes)
| Protocol | Port | Purpose | CNI Plugin |
|---|---|---|---|
| **UDP** | `4789` | VXLAN Overlay | Flannel, Calico, Canal |
| **TCP** | `179` | BGP Routing Mesh | Calico (BGP mode) |
| **UDP** | `51820 / 51821`| WireGuard Encryption | Flannel / Calico WireGuard |
| **TCP / UDP** | `4240 / 8472`| Cilium health & Geneve | Cilium |
