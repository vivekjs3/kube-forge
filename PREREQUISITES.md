# Talos Linux Prerequisites & System Requirements

Before provisioning Talos Linux nodes, ensure your environment meets the following specifications.

---

## 1. Hardware Requirements

| Node Type | Minimum vCPU | Recommended vCPU | Minimum RAM | Recommended RAM | Storage |
|---|---|---|---|---|---|
| **Control Plane** | 2 vCPU | 2-4 vCPU | 2.5 GB | 4 GB | 20+ GB NVMe/SSD |
| **Worker Node** | 1 vCPU | 2 vCPU | 1.5 GB | 2 GB | 20+ GB NVMe/SSD |

---

## 2. Booting Talos Linux

Unlike general Linux which is installed via apt/yum, Talos is booted as a self-contained image:
- **Bare-Metal:** Boot via ISO, USB flash drive, or network PXE (iPXE).
- **Proxmox / KVM / VMware:** Attach the official `metal-amd64.iso` or import cloud qcow2 image.
- **Download ISO:** Obtain the latest official ISO from `https://factory.talos.dev/`.

---

## 3. Operator Workstation Tooling

The operator machine requires the `talosctl` CLI utility:
```bash
# Download talosctl
sudo curl -sL https://talos.dev/install | sh
talosctl version --client
```

---

## 4. Firewall Port Matrix

| Protocol | Port | Source | Description |
|---|---|---|---|
| **TCP** | `50000` | Operators, talosctl | Talos gRPC API Server |
| **TCP** | `6443` | All nodes, kubectl | Kubernetes API Server |
| **TCP** | `2379-2380` | Control plane nodes | etcd cluster communication |
| **TCP** | `10250` | Control plane | Kubelet API |
| **UDP** | `8472 / 4789`| All nodes | Flannel / Calico overlay |
