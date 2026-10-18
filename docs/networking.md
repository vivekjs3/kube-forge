# Kubeadm Networking & CNI Options

`kubeadm` intentionally leaves the networking layer unconfigured during initialization. This allows platform engineers to select the optimal Container Network Interface (CNI) provider.

---

## 1. Supported CNI Providers

| Feature | Flannel | Calico | Cilium |
|---|---|---|---|
| **Primary Mechanism** | Simple VXLAN overlay | VXLAN or routed BGP | eBPF kernel bytecode |
| **Network Policy** | ❌ No (requires Canal) | ✅ Yes (Full L3/L4 NetworkPolicy) | ✅ Yes (L3/L4/L7 + DNS) |
| **Routing Protocol** | Encapsulated UDP 4789 | BGP (Port 179) or VXLAN | eBPF direct routing |
| **Resource Usage** | Extremely low (~50MB) | Low (~100-150MB) | Moderate (~250-400MB) |
| **Learning Curve** | Minimal (Plug-and-play) | Intermediate | Intermediate to Advanced |
| **kube-forge Script** | Included (`--flannel`) | Default (`--calico`) | Documented |

---

## 2. Pod CIDR Subnet Requirements

When initializing `kubeadm`, you must pass a `--pod-network-cidr` matching your intended CNI:
- **Flannel:** Default is `10.244.0.0/16`
- **Calico:** Default is `192.168.0.0/16` (or `10.244.0.0/16` when configured)

> [!IMPORTANT]
> The Pod Network CIDR must **never overlap** with your physical host LAN (e.g. `10.10.10.0/24`) or the Service ClusterIP CIDR (`10.96.0.0/12`).

---

## 3. How Calico Implements Pod Routing

1. **IPAM (IP Address Management):** Calico divides the cluster Pod CIDR into smaller `/26` blocks and assigns one block to each node.
2. **Felix Daemon:** Runs on every node, watching Kubernetes endpoints and programming the Linux kernel routing table and `iptables` chains.
3. **BIRD Internet Routing Daemon:** In BGP mode, BIRD establishes BGP peerings with adjacent nodes to advertise local pod routes without packet encapsulation overhead.
