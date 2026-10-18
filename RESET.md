# MicroK8s Teardown & Reset Guide

This document describes how to reset cluster state or completely remove the MicroK8s snap.

---

## 1. Automated Teardown via `scripts/reset.sh`

```bash
sudo ./scripts/reset.sh
```
To purge non-interactively:
```bash
sudo ./scripts/reset.sh --force
```

---

## 2. Manual Teardown Commands

### Option A: Reset Cluster State (Keep Snap Installed)
```bash
microk8s reset
```

### Option B: Complete Snap Uninstallation & Purge
```bash
sudo microk8s stop
sudo snap remove microk8s --purge
sudo rm -rf /var/snap/microk8s
rm -rf "$HOME/.kube"
```
