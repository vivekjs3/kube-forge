# K3s Teardown & Uninstall Guide

This document describes how to safely uninstall K3s, terminate all running container workloads, and restore nodes to a clean state.

---

## ⚠️ Important Notice

> [!WARNING]
> Uninstalling K3s permanently removes:
> - The embedded SQLite database and all cluster resources
> - All local persistent storage volumes in `/var/lib/rancher/k3s/storage/`
> - Cluster TLS certificates and keys

---

## 1. Automated Teardown via `scripts/reset.sh`

```bash
sudo ./scripts/reset.sh
```
To run non-interactively without prompt:
```bash
sudo ./scripts/reset.sh --force
```

---

## 2. Using Built-in Official K3s Scripts

K3s installs dedicated uninstall scripts during installation:

### On K3s Server Node:
```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

### On K3s Agent Node:
```bash
sudo /usr/local/bin/k3s-agent-uninstall.sh
```

---

## 3. Manual Cleanup Checklist

If cleaning manually:
```bash
# 1. Stop service
sudo systemctl stop k3s || sudo systemctl stop k3s-agent

# 2. Kill orphan containers and shims
sudo pkill -9 -f "k3s/data" || true

# 3. Clean filesystems
sudo rm -rf /etc/rancher/k3s
sudo rm -rf /var/lib/rancher/k3s
sudo rm -rf /run/k3s
sudo rm -rf /var/lib/kubelet
rm -rf "$HOME/.kube"

# 4. Flush iptables
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X
```
