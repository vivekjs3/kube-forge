# Kubernetes The Hard Way: Troubleshooting Guide

Because manual installation exposes every binary flag and configuration file directly, troubleshooting provides unmatched visibility into Kubernetes failure modes.

---

## 1. etcd Service Fails to Start: Certificate or Port Conflict

### Problem:
`etcd.service` exits with code 1.

### Cause:
Missing TLS certificates in `/etc/etcd/`, wrong file permissions, or port `2379` already in use.

### Check:
```bash
sudo journalctl -u etcd -n 50 --no-pager
sudo ls -l /etc/etcd/
```

### Fix:
Verify certificate permissions:
```bash
sudo chmod 600 /etc/etcd/*-key.pem
sudo chmod 644 /etc/etcd/*.pem
sudo systemctl restart etcd
```

### Validation:
```bash
ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem
```

---

## 2. API Server Fails: `etcd client connection failed`

### Problem:
`kube-apiserver.service` exits repeatedly.

### Cause:
API server cannot reach etcd over mTLS, or etcd is still starting up.

### Check:
```bash
sudo journalctl -u kube-apiserver -n 50 --no-pager | grep -i etcd
```

### Fix:
Ensure `etcd.service` is healthy and listening on `2379`:
```bash
sudo ss -tulpn | grep 2379
sudo systemctl restart etcd
sudo systemctl restart kube-apiserver
```

### Validation:
```bash
curl -k https://localhost:6443/version
```

---

## 3. RBAC Error: API Server Cannot Stream Logs or Exec from Kubelet

### Problem:
Running `kubectl logs` or `kubectl exec` returns:
`Error from server (Forbidden): nodes "k8s-worker-01" is forbidden: User "kubernetes" cannot get resource "nodes/proxy"`

### Cause:
The API server uses the `kubernetes.pem` certificate (`CN=kubernetes`) to speak to Kubelet on port 10250, but lacks an RBAC `ClusterRoleBinding` granting it the `system:kubelet-api-admin` role.

### Check:
```bash
kubectl get clusterrolebinding kube-apiserver-kubelet
```

### Fix:
Apply the RBAC binding:
```bash
kubectl create clusterrolebinding kube-apiserver-kubelet-admin \
  --clusterrole=system:kubelet-api-admin \
  --user=kubernetes
```

### Validation:
```bash
kubectl logs <pod-name>
```
