# K3s Networking Architecture

K3s comes with a pre-configured networking stack designed for zero-configuration startup.

---

## 1. Embedded Flannel CNI

- **Default Backend:** VXLAN on UDP port `8472` (interface `flannel.1`).
- **Alternative Backends:**
  - `host-gw`: Direct IP routing when all nodes share a single L2 broadcast domain (fastest, zero encapsulation overhead).
  - `wireguard-native`: Encrypted pod-to-pod communication.
  - `none`: Disables embedded Flannel to permit installing Calico or Cilium manually.

---

## 2. Ingress & Load Balancing

- **Traefik Ingress Controller:** Automatically deployed as a HelmChart resource in `kube-system`. Traefik listens on host ports 80 (HTTP) and 443 (HTTPS) across all server nodes.
- **ServiceLB (klipper-lb):** When a service is created with `type: LoadBalancer`, ServiceLB creates a DaemonSet pod on each node that binds the Service port to the node's external IP address via iptables NAT rules.
