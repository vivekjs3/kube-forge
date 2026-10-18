# Kubernetes The Hard Way: Validation Guide

Follow this guide to verify manual binary installations.

---

## 1. Systemd Service Status

Verify that all system services are active:
```bash
sudo systemctl status etcd kube-apiserver kube-controller-manager kube-scheduler --no-pager
```

---

## 2. Cluster Component Status via `kubectl`

```bash
kubectl get nodes -o wide
kubectl get componentstatuses 2>/dev/null || true
```

---

## 3. Workload Deployment Smoke Test

Deploy the validation manifest in `examples/test-workload.yaml`:
```bash
kubectl apply -f examples/test-workload.yaml
kubectl wait --for=condition=Ready pod/curl-test --timeout=60s
kubectl exec -i curl-test -- curl -s http://nginx-service:80
kubectl delete -f examples/test-workload.yaml
```
