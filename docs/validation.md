# Kubespray Cluster Validation Guide

Follow this guide to verify a Kubespray deployment.

---

## 1. Verify via Controller Machine

Once the playbook completes, copy the generated admin kubeconfig from the control plane node:
```bash
mkdir -p "$HOME/.kube"
ssh <USER>@10.10.10.10 "sudo cat /etc/kubernetes/admin.conf" > "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"
```

---

## 2. Check Node & Pod Health

```bash
kubectl get nodes -o wide
kubectl get pods -A
```
