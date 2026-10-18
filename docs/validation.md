# Kubeadm Cluster Validation Guide

To ensure that your `kubeadm` cluster is fully operational before deploying production workloads, perform this step-by-step validation.

---

## 1. Node Status Validation

```bash
kubectl get nodes -o wide
```
**Expected Outcome:**
- All nodes (`k8s-control-01`, `k8s-worker-01`, etc.) must display status `Ready`.
- Container runtime should show `containerd://...`.
- Kernel version and OS must match your provisioned nodes.

---

## 2. Core Control Plane Pod Health

```bash
kubectl get pods -n kube-system -o wide
```
**Expected Outcome:**
- `etcd-<node>`: `1/1 Running`
- `kube-apiserver-<node>`: `1/1 Running`
- `kube-controller-manager-<node>`: `1/1 Running`
- `kube-scheduler-<node>`: `1/1 Running`
- `kube-proxy-*`: `1/1 Running` on every node
- `coredns-*`: `1/1 Running` (2 replicas with assigned Pod IPs)
- CNI pods (`calico-node-*` or `kube-flannel-ds-*`): `1/1 Running` on every node

---

## 3. End-to-End Workload & Networking Validation

Deploy the sample workload manifest from `examples/test-workload.yaml`:

```bash
# 1. Apply test deployment and service
kubectl apply -f examples/test-workload.yaml

# 2. Wait for deployment rollout
kubectl rollout status deployment/nginx-test -n default --timeout=90s

# 3. Test Service ClusterIP routing from inside a pod
kubectl exec -i curl-test -n default -- curl -s -m 5 http://nginx-service.default.svc.cluster.local:80

# 4. Clean up test workload
kubectl delete -f examples/test-workload.yaml
```
