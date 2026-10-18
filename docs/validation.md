# K3s Cluster Validation Guide

Follow this guide to verify that K3s is healthy, ingress routing functions, and local storage works as expected.

---

## 1. Quick Cluster Status Check

```bash
kubectl get nodes -o wide
```
**Expected:** All server and agent nodes should be `Ready` with K3s version displayed.

---

## 2. System Pods Check

```bash
kubectl get pods -A
```
**Expected:**
- `coredns-*`: Running
- `traefik-*`: Running
- `local-path-provisioner-*`: Running
- `helm-install-*`: Completed

---

## 3. Workload & Ingress Test

Deploy the sample workload in `examples/test-workload.yaml`:
```bash
kubectl apply -f examples/test-workload.yaml
```
Verify the HTTP response through the Traefik Ingress:
```bash
curl -H "Host: nginx.lab.local" http://localhost/
# Output should contain "Welcome to nginx!"
```
Clean up:
```bash
kubectl delete -f examples/test-workload.yaml
```
