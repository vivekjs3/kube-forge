# K3s Packaged Components

This document describes the services, binaries, and storage components packaged into K3s.

---

## 1. Packaged Software Layers

| Component | Standard Kubernetes Equivalent | Notes |
|---|---|---|
| **`k3s` binary** | Single binary replacing 8+ components | Compiled with embedded containerd, runc, crictl, kubectl |
| **`kine`** | `etcd` | Translates etcd v3 API to SQLite, MySQL, or Postgres |
| **`flannel`** | Modular CNI (Calico/Cilium) | Embedded directly into the k3s process |
| **`traefik`** | Ingress-NGINX / Contour | Deployed as a HelmChart CRD in `kube-system` |
| **`local-path-provisioner`** | Cloud EBS / Ceph / NFS | Provides dynamic storage from `/var/lib/rancher/k3s/storage/` |
| **`servicelb`** | MetalLB / Cloud Provider LB | Routes external traffic to service ports |
