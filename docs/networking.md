# Kubernetes The Hard Way: Networking Architecture

Understanding manual Kubernetes networking exposes how Linux network namespaces, bridges, and static routes connect Pods without opaque CNI daemons.

---

## 1. The Pod CIDR Allocation Model

Each worker node is manually assigned a distinct `/24` pod subnet from the cluster-wide `10.200.0.0/16` range:
- `k8s-worker-01`: Subnet `10.200.0.0/24`
- `k8s-worker-02`: Subnet `10.200.1.0/24`

The CNI bridge plugin creates a local Linux bridge (`cbr0`) on each node assigned the `.1` gateway IP (e.g. `10.200.0.1/24`).

---

## 2. Cross-Node Route Table

On physical or virtual networks where nodes share an L2 broadcast domain, packets between nodes can be routed directly by adding kernel routing table entries:
```bash
# On worker-01: route traffic destined for worker-02's pods via worker-02's host IP
ip route add 10.200.1.0/24 via 10.10.10.12

# On worker-02: route traffic destined for worker-01's pods via worker-01's host IP
ip route add 10.200.0.0/24 via 10.10.10.11
```
This is the fundamental principle behind Calico BGP mode and Flannel `host-gw`!
