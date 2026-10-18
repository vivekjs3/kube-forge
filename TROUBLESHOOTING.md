# K3s Troubleshooting Guide

This guide details common failures encountered when deploying and operating **K3s**, structured according to the **Problem -> Cause -> Check -> Fix -> Validation** protocol.

---

## 1. Agent Registration Fails: `401 Unauthorized`

### Problem:
Running `k3s agent` fails with:
`level=fatal msg="starting kubernetes: preparing server: response 401: Unauthorized"`

### Cause:
The bootstrap token passed to `k3s agent` does not match the token in `/var/lib/rancher/k3s/server/node-token` on the server.

### Check:
```bash
# On the server, view the exact token:
sudo cat /var/lib/rancher/k3s/server/node-token
```

### Fix:
Re-run the agent installation with the exact token string:
```bash
sudo ./scripts/05-join-agents.sh https://<SERVER_IP>:6443 "<CORRECT_TOKEN>"
```

### Validation:
```bash
# On the server:
kubectl get nodes
# The new agent node should show Ready
```

---

## 2. Traefik Fails to Start: Port 80 / 443 Already in Use

### Problem:
Traefik ingress controller pod remains in `CrashLoopBackOff` or `Pending`:
`failed to bind to 0.0.0.0:80: address already in use`

### Cause:
A local web server (such as Apache, Nginx, or caddy) is already bound to port 80 or 443 on the host OS.

### Check:
```bash
sudo ss -tulpn | grep -E ':80\s|:443\s'
```

### Fix:
Either stop the conflicting host service:
```bash
sudo systemctl stop nginx || sudo systemctl stop apache2
```
Or disable packaged Traefik if you plan to install your own ingress controller:
Add to `/etc/rancher/k3s/config.yaml`:
```yaml
disable:
  - traefik
```
And restart K3s:
```bash
sudo systemctl restart k3s
```

### Validation:
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
```

---

## 3. Non-Root User Gets `permission denied` Accessing Kubeconfig

### Problem:
Running `kubectl get nodes` as a regular user returns:
`error: error loading config file "/etc/rancher/k3s/k3s.yaml": open /etc/rancher/k3s/k3s.yaml: permission denied`

### Cause:
K3s creates `/etc/rancher/k3s/k3s.yaml` with mode `0600` (owned by root).

### Check:
```bash
ls -l /etc/rancher/k3s/k3s.yaml
```

### Fix:
Run `./scripts/04-configure.sh`, or copy the kubeconfig into `$HOME/.kube/config`:
```bash
mkdir -p "$HOME/.kube"
sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
sudo chown $(id -u):$(id -g) "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"
```

### Validation:
```bash
kubectl get nodes
```

---

## 4. SQLite Database Locks (`database is locked`)

### Problem:
K3s server logs report:
`error while executing txn: database is locked`

### Cause:
Slow storage disk (e.g. low-end SD card on Raspberry Pi) causing SQLite write transaction timeouts under load.

### Check:
```bash
sudo journalctl -u k3s -n 50 --no-pager | grep -i sqlite
```

### Fix:
1. Ensure the underlying filesystem is not mounted read-only.
2. For multi-node or heavy production workloads, switch to embedded etcd (`--cluster-init`) or external PostgreSQL/MySQL.

### Validation:
```bash
sudo systemctl status k3s
```
