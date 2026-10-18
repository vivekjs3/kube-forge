# MicroK8s Prerequisites & System Requirements

Before installing MicroK8s, ensure that your host meets the system, memory, and firewall port requirements.

---

## 1. Hardware Requirements

| Role | Minimum vCPU | Recommended vCPU | Minimum RAM | Recommended RAM | Storage |
|---|---|---|---|---|---|
| **Single Node** | 2 vCPU | 2-4 vCPU | 2 GB | 4 GB | 20+ GB |
| **Clustered Node**| 2 vCPU | 4 vCPU | 3 GB | 4 GB | 30+ GB |

---

## 2. Software & Snapd Prerequisites

MicroK8s requires `snapd` (installed by default on Ubuntu):
```bash
sudo apt-get update -y
sudo apt-get install -y snapd iptables
```

---

## 3. Firewall Port Matrix

| Protocol | Port | Source | Description |
|---|---|---|---|
| **TCP** | `16443` | All nodes, kubectl | MicroK8s Kubernetes API Server (Default) |
| **TCP** | `10250` | Node peers | Kubelet API |
| **TCP** | `25000` | Node peers | MicroK8s cluster join API daemon |
| **TCP** | `19001` | Control plane nodes | Dqlite Raft consensus synchronization |
| **UDP** | `4789` | All nodes | Calico VXLAN overlay encapsulation |
| **TCP** | `80 / 443`| External clients | Ingress Controller |
