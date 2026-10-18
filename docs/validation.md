# Talos Linux Cluster Validation Guide

Follow this guide to verify a Talos cluster.

---

## 1. Talosctl Health Inspection

```bash
talosctl -n 10.10.10.10 health
```
**Expected Output:**
- `waiting for etcd to be healthy: OK`
- `waiting for apiserver to be healthy: OK`
- `waiting for kubelet to be healthy: OK`
- `waiting for all nodes to be ready: OK`

---

## 2. Retrieve Kubeconfig & Inspect Nodes

```bash
talosctl -n 10.10.10.10 kubeconfig .
kubectl get nodes -o wide
```
