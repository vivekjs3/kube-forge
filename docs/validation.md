# MicroK8s Cluster Validation Guide

Follow this guide to verify a MicroK8s installation.

---

## 1. Status & Readiness

```bash
microk8s status --wait-ready
microk8s kubectl get nodes -o wide
```

---

## 2. Ingress & Addon Verification

```bash
microk8s kubectl get pods -A
```
Ensure `coredns` and `nginx-ingress-microk8s-controller` pods are running.
