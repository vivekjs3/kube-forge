# RKE2 Networking Architecture

RKE2 ships by default with **Canal CNI** and **NGINX Ingress Controller**.

---

## 1. Canal CNI: The Best of Calico and Flannel

Canal is an integrated networking solution combining:
1. **Flannel:** Manages VXLAN overlay encapsulation on UDP port `8472` for cross-node packet transport.
2. **Calico Policy Engine:** Evaluates and enforces standard Kubernetes `NetworkPolicy` objects using host iptables.

---

## 2. Ingress Controller: NGINX Ingress

Unlike K3s (which defaults to Traefik), RKE2 deploys the standard **NGINX Ingress Controller** by default:
- Automatically listens on host ports 80 and 443.
- Integrated with ServiceLB for local IP binding.
- Can be disabled in `/etc/rancher/rke2/config.yaml` using:
  ```yaml
  disable:
    - rke2-ingress-nginx
  ```
