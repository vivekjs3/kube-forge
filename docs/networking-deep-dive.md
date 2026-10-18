# Kubernetes Networking Deep Dive

Kubernetes networking follows strict foundational tenets that differentiate it from traditional host-centric networking. This guide explains how IP address management, pod-to-pod routing, overlay tunnels, and service discovery function.

---

## 1. The Core Networking Invariants

Every Kubernetes network implementation must satisfy three non-negotiable rules:
1. All Pods can communicate with all other Pods on any node **without Network Address Translation (NAT)**.
2. All agents on a node (e.g. `kubelet`) can communicate with all Pods on that same node.
3. The IP that a Pod sees itself as is the same IP that every other Pod sees it as.

---

## 2. Address Spaces (The 3 Subnets)

```
+---------------------------------------------------------------------------------------+
| 1. Node Network (Physical / VM LAN)                                                   |
|    Subnet: 10.10.10.0/24                                                              |
|    master-01: 10.10.10.10      worker-01: 10.10.10.11      worker-02: 10.10.10.12     |
+---------------------------------------------------------------------------------------+
| 2. Pod Network (Allocated by CNI)                                                     |
|    Cluster-Wide CIDR: 10.244.0.0/16                                                   |
|    worker-01 Pod Subnet: 10.244.1.0/24         worker-02 Pod Subnet: 10.244.2.0/24    |
|    Pod A: 10.244.1.5                            Pod B: 10.244.2.8                     |
+---------------------------------------------------------------------------------------+
| 3. Service Network (Virtual ClusterIPs)                                               |
|    CIDR: 10.96.0.0/12                                                                 |
|    kubernetes.default: 10.96.0.1               kube-dns: 10.96.0.10                   |
+---------------------------------------------------------------------------------------+
```

---

## 3. Pod-to-Pod Communication: Cross-Node Packet Flow

When Pod A (`10.244.1.5` on `worker-01`) sends a packet to Pod B (`10.244.2.8` on `worker-02`):

```
+----------------------------------+             +----------------------------------+
|           WORKER NODE 01         |             |           WORKER NODE 02         |
|                                  |             |                                  |
|  +----------------------------+  |             |  +----------------------------+  |
|  |     Pod A (10.244.1.5)     |  |             |  |     Pod B (10.244.2.8)     |  |
|  |           [eth0]           |  |             |  |           [eth0]           |  |
|  +--------------|-------------+  |             |  +--------------^-------------+  |
|                 | (veth pair)    |             |                 | (veth pair)    |
|  +--------------v-------------+  |             |  +--------------|-------------+  |
|  |          [vethXXXX]        |  |             |  |          [vethYYYY]        |  |
|  |              |             |  |             |  |              ^             |  |
|  |              v             |  |             |  |              |             |  |
|  |        Linux Bridge /      |  |             |  |        Linux Bridge /      |  |
|  |          Routing Table     |  |             |  |          Routing Table     |  |
|  +--------------|-------------+  |             |  +--------------|-------------+  |
|                 |                |             |                 |                |
|                 | (Encapsulate)  |             |                 | (Decapsulate)  |
|  +--------------v-------------+  |   Underlay  |  +--------------|-------------+  |
|  |  VXLAN / Geneve / Direct   |==|=============|==|  VXLAN / Geneve / Direct   |  |
|  |     NIC: 10.10.10.11       |  |  Network    |  |     NIC: 10.10.10.12       |  |
|  +----------------------------+  |             |  +----------------------------+  |
+----------------------------------+             +----------------------------------+
```

### Steps:
1. **Packet Origin:** Pod A transmits an IP packet with source `10.244.1.5` and destination `10.244.2.8`.
2. **Virtual Ethernet:** The packet leaves Pod A's network namespace via the virtual ethernet cable (`eth0`) and arrives at `vethXXXX` in the root host namespace.
3. **Routing Decision:** The host Linux kernel inspects the destination IP (`10.244.2.8`).
   - If using **VXLAN (Flannel / Calico VXLAN mode)**: The packet is encapsulated into an outer UDP datagram with destination port `4789` and destination host `10.10.10.12`.
   - If using **BGP (Calico BGP mode)**: The host routes the raw packet directly across the top-of-rack physical switch to `10.10.10.12`.
4. **Transit:** The physical network transports the packet between nodes.
5. **Decapsulation:** `worker-02` receives the packet, decapsulates the VXLAN header, recognizes the inner destination `10.244.2.8`, and injects it into `vethYYYY`.
6. **Arrival:** Pod B receives the packet on its `eth0` interface with original source IP intact.

---

## 4. Service Networking & ClusterIP Translation

Service IPs are **virtual**: they do not exist on any physical or virtual network interface. Instead, the Linux kernel intercepts packets destined for the Service CIDR.

```
Client Pod
    |
    | (Destination: 10.96.0.150:80)
    v
Kernel Netfilter (PREROUTING)
    |
    +---> kube-proxy iptables / IPVS rule
            |
            | Random / Round-Robin DNAT selection
            v
    (Destination rewritten to: 10.244.2.8:8080)
    |
    v
Forwarded to Target Pod B
```

---

## 5. DNS Resolution Flow

CoreDNS provides internal service discovery via the cluster domain (`cluster.local`).

When a Pod queries `my-service.my-namespace.svc.cluster.local`:
1. The Pod's `/etc/resolv.conf` specifies `nameserver 10.96.0.10` (the CoreDNS Service IP).
2. The packet hits the local host's `iptables` rules and is balanced to one of the healthy CoreDNS Pod replicas.
3. CoreDNS queries its in-memory cache of Kubernetes API resources.
4. CoreDNS replies with the Service's virtual `ClusterIP`.
