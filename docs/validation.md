# RKE2 Cluster Validation Guide

Follow this guide to verify an RKE2 cluster deployment.

---

## 1. Quick Cluster Status Check

```bash
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
/var/lib/rancher/rke2/bin/kubectl get nodes -o wide
```
**Expected:** All server and agent nodes should display status `Ready`.

---

## 2. In-Cluster Pods Check

```bash
/var/lib/rancher/rke2/bin/kubectl get pods -A
```
**Expected Pods in `kube-system`:**
- `etcd-*`
- `kube-apiserver-*`
- `kube-controller-manager-*`
- `kube-scheduler-*`
- `rke2-canal-*` (Canal CNI daemonset)
- `rke2-ingress-nginx-controller-*`
- `rke2-coredns-*`
- `rke2-metrics-server-*`
