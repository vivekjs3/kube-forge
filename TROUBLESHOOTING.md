# Kubeadm Troubleshooting Guide

This guide details the most common failure modes encountered during and after `kubeadm` cluster provisioning, organized by the standard **Problem -> Cause -> Check -> Fix -> Validation** protocol.

---

## 1. Node Remains in `NotReady` Status

### Problem:
Running `kubectl get nodes` shows nodes in `NotReady` state.

### Cause:
The Container Network Interface (CNI) plugin has not been deployed, or its agent daemon is failing. Kubelet reports `NetworkPluginNotReady: Network plugin returns error: cni plugin not initialized`.

### Check:
```bash
# Describe the affected node
kubectl describe node <node-name> | grep -A 5 -i "Conditions:"

# Inspect kubelet logs
sudo journalctl -u kubelet -n 50 --no-pager
```

### Fix:
Deploy a supported CNI plugin (e.g. Calico or Flannel):
```bash
./scripts/06-install-cni.sh
```

### Validation:
```bash
kubectl get nodes
# Status must transition from NotReady to Ready within 60 seconds
```

---

## 2. CoreDNS Pods Stuck in `Pending`

### Problem:
`kubectl get pods -n kube-system` shows `coredns-*` pods in `Pending` state indefinitely.

### Cause:
CoreDNS requires an active CNI plugin to allocate non-host IP addresses. Until a CNI is installed, the scheduler cannot bind CoreDNS to any node.

### Check:
```bash
kubectl describe pod -n kube-system -l k8s-app=kube-dns
# Look for: 0/1 nodes are available: 1 node(s) had untolerated taint {node.kubernetes.io/not-ready: }
```

### Fix:
Install the CNI plugin via `./scripts/06-install-cni.sh`. If on a single-node cluster without workers, also untaint the control plane:
```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

### Validation:
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
# Pod status should be Running with a Pod IP (e.g. 10.244.0.2)
```

---

## 3. Kubelet Fails to Start (`cgroup driver mismatch`)

### Problem:
`kubelet.service` enters a crash loop immediately after boot:
`Failed to run kubelet: misconfiguration: kubelet cgroup driver: "systemd" is different from docker cgroup driver: "cgroupfs"`

### Cause:
The container runtime (`containerd`) was configured with `SystemdCgroup = false`, but modern Kubernetes requires `SystemdCgroup = true`.

### Check:
```bash
sudo journalctl -u kubelet -e --no-pager | grep -i cgroup
grep -i SystemdCgroup /etc/containerd/config.toml
```

### Fix:
Update `/etc/containerd/config.toml`:
```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true
```
Restart services:
```bash
sudo systemctl restart containerd
sudo systemctl restart kubelet
```

### Validation:
```bash
sudo systemctl is-active kubelet
# Output: active
```

---

## 4. API Server Connection Refused on Port 6443

### Problem:
Running `kubectl get nodes` returns:
`The connection to the server 10.10.10.10:6443 was refused - did you specify the right host or port?`

### Cause:
The `kube-apiserver` static pod container is crashed or `containerd` is not running.

### Check:
```bash
# Check if containerd is alive
sudo systemctl status containerd

# Check running static containers
sudo crictl ps -a | grep apiserver

# Inspect API server container logs
sudo crictl logs $(sudo crictl ps -a --name kube-apiserver -q | head -n 1)
```

### Fix:
1. Verify `etcd` is healthy (if etcd crashes, the API server exits immediately):
   ```bash
   sudo crictl ps -a --name etcd
   ```
2. Verify certificates in `/etc/kubernetes/pki/` have not expired or been deleted.
3. Check that port 6443 is not occupied by another process:
   ```bash
   sudo ss -tulpn | grep 6443
   ```

### Validation:
```bash
curl -k https://localhost:6443/livez
# Output: ok
```

---

## 5. Worker Node Join Failure (`token expired` or `hash mismatch`)

### Problem:
`kubeadm join` fails with:
`[discovery] Failed to connect to API Server "10.10.10.10:6443": token is invalid or expired`

### Cause:
Bootstrap tokens expire after 24 hours by default. Alternatively, the CA certificate hash string was truncated.

### Check:
```bash
# On the control plane, list active tokens
kubeadm token list
```

### Fix:
Generate a fresh join token and command directly on the control plane:
```bash
kubeadm token create --print-join-command
```
Run the freshly outputted command on the worker node with `sudo`.

### Validation:
```bash
# On the control plane:
kubectl get nodes
```

---

## 6. Pod-to-Pod Cross-Node Network Failure

### Problem:
Pods on `k8s-control-01` cannot ping or curl Pods on `k8s-worker-01`.

### Cause:
Firewall blocking overlay encapsulation port (UDP 4789 for VXLAN) or `net.ipv4.ip_forward` is disabled on the host kernel.

### Check:
```bash
# Check IP forwarding on both nodes
sysctl net.ipv4.ip_forward

# Check firewall status
sudo ufw status
```

### Fix:
Enable forwarding and permit VXLAN traffic:
```bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo ufw allow 4789/udp
```

### Validation:
Deploy the validation workload in `examples/test-workload.yaml` and run `./scripts/08-validate.sh`.
