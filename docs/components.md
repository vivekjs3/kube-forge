# RKE2 Packaged Components

This document details the binaries, system services, and packaged charts provided by RKE2.

---

## 1. System Services

- **`rke2-server.service`**: The control plane daemon managing etcd, kube-apiserver, kube-scheduler, kube-controller-manager, and the embedded kubelet.
- **`rke2-agent.service`**: The worker daemon managing the embedded kubelet, containerd, and node networking.

---

## 2. Packaged Binaries

RKE2 installs CLI tools into `/var/lib/rancher/rke2/bin/`:
- `kubectl`
- `crictl`
- `ctr`

Add them to your environment PATH:
```bash
export PATH=$PATH:/var/lib/rancher/rke2/bin
```
