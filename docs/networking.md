# MicroK8s Networking Architecture

MicroK8s uses **Calico** as its default embedded Container Network Interface (CNI).

---

## 1. Network Architecture

- **Pod CIDR:** Default is `10.1.0.0/16`.
- **Service CIDR:** Default is `10.152.183.0/24`.
- **CoreDNS:** Configured as an addon (`microk8s enable dns`) listening on `10.152.183.10`.
- **Ingress Controller:** Bundled NGINX ingress controller deployed via `microk8s enable ingress`.
- **Load Balancer (MetalLB):** Deployed via `microk8s enable metallb:<IP_RANGE>`.
