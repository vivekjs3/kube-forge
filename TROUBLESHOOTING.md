# MicroK8s Troubleshooting Guide

This guide details common failures encountered when deploying and managing **MicroK8s**, structured according to the **Problem -> Cause -> Check -> Fix -> Validation** protocol.

---

## 1. Permission Denied Running `microk8s kubectl`

### Problem:
Running `microk8s kubectl` outputs:
`Insufficient permissions to access MicroK8s. Please run as root or add your user to the 'microk8s' group.`

### Cause:
The local user account has not been added to the `microk8s` system group, or the group membership has not refreshed in the active shell.

### Fix:
Add user and re-authenticate:
```bash
sudo usermod -aG microk8s "$USER"
sudo chown -f -R "$USER" "$HOME/.kube" 2>/dev/null || true
newgrp microk8s
```

### Validation:
```bash
microk8s kubectl get nodes
```

---

## 2. MicroK8s Daemon Not Running (`microk8s is not running`)

### Problem:
`microk8s status` reports `microk8s is not running`.

### Cause:
Snap services were stopped or the host kernel had swap active with strict memory limits.

### Check:
```bash
sudo snap services microk8s
```

### Fix:
Restart the snap service suite:
```bash
microk8s start
microk8s status --wait-ready
```

### Validation:
```bash
microk8s status
# Output: microk8s is running
```

---

## 3. Node Join Fails: Port 25000 Unreachable

### Problem:
`microk8s join 10.10.10.10:25000/...` times out.

### Cause:
Host firewall blocking TCP port `25000` on the initial cluster node.

### Fix:
Open port `25000` on the control plane node:
```bash
sudo ufw allow 25000/tcp
```
