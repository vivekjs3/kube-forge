# RKE2 Teardown & Uninstall Guide

This document describes how to safely uninstall RKE2, destroy cluster state, and return nodes to a clean state.

---

## ⚠️ Important Warning

> [!WARNING]
> Resetting RKE2 permanently deletes:
> - The etcd database and cluster state
> - In-cluster persistent volumes
> - PKI certificates and bootstrap tokens

---

## 1. Automated Reset Script

```bash
sudo ./scripts/reset.sh
```
To run non-interactively without prompt:
```bash
sudo ./scripts/reset.sh --force
```

---

## 2. Using Built-in Official RKE2 Scripts

### On Server:
```bash
sudo /usr/local/bin/rke2-uninstall.sh
```

### On Agent:
```bash
sudo /usr/local/bin/rke2-agent-uninstall.sh
```

---

## 3. Manual Cleanup Checklist

```bash
# 1. Stop and disable services
sudo systemctl stop rke2-server 2>/dev/null || true
sudo systemctl stop rke2-agent 2>/dev/null || true

# 2. Unmount any lingering pod volumes
sudo sh -c 'grep -E "/var/lib/rancher/rke2" /proc/mounts | cut -d" " -f2 | sort -r | xargs -r -t -m umount'

# 3. Remove state directories
sudo rm -rf /etc/rancher/rke2
sudo rm -rf /var/lib/rancher/rke2
sudo rm -rf /run/k3s
sudo rm -rf /var/lib/kubelet
rm -rf "$HOME/.kube"

# 4. Flush iptables
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X
```
