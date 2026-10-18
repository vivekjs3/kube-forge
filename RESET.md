# Kubernetes The Hard Way: Teardown & Cleanup

This document describes how to cleanly stop all manual systemd services, remove binaries, and purge PKI certificates.

---

## 1. Automated Teardown Script

```bash
sudo ./scripts/reset.sh
```
To run non-interactively without prompt:
```bash
sudo ./scripts/reset.sh --force
```

---

## 2. Manual Step-by-Step Cleanup Checklist

```bash
# 1. Stop and disable all services
sudo systemctl stop kube-apiserver kube-controller-manager kube-scheduler etcd kubelet kube-proxy containerd 2>/dev/null || true
sudo systemctl disable kube-apiserver kube-controller-manager kube-scheduler etcd kubelet kube-proxy containerd 2>/dev/null || true

# 2. Remove systemd unit files
sudo rm -f /etc/systemd/system/kube-*.service
sudo rm -f /etc/systemd/system/etcd.service
sudo rm -f /etc/systemd/system/containerd.service
sudo systemctl daemon-reload

# 3. Remove state and PKI directories
sudo rm -rf /etc/etcd /var/lib/etcd
sudo rm -rf /var/lib/kubernetes /var/lib/kubelet
sudo rm -rf /etc/cni/net.d /var/lib/cni
sudo rm -rf /etc/containerd
rm -rf "$HOME/.kube"

# 4. Remove downloaded binaries
sudo rm -f /usr/local/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kubelet,kube-proxy}
sudo rm -f /usr/local/bin/{etcd,etcdctl}
sudo rm -f /usr/local/bin/{cfssl,cfssljson}
```
