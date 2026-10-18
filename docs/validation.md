# Minikube Cluster Validation Guide

Follow this guide to verify that Minikube is operational on your machine.

---

## 1. Minikube Status Check

```bash
minikube status
```
**Expected Output:**
- `type: Control Plane`
- `host: Running`
- `kubelet: Running`
- `apiserver: Running`
- `kubeconfig: Configured`

---

## 2. Cluster Nodes & Addons Check

```bash
kubectl get nodes -o wide
minikube addons list | grep enabled
```
