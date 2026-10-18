# RKE2 Troubleshooting Guide

This guide details common failures encountered during the deployment and operation of **RKE2**, following the **Problem -> Cause -> Check -> Fix -> Validation** protocol.

---

## 1. Agent Fails to Join: Connection to Port 9345 Refused or Timed Out

### Problem:
Running `rke2 agent` fails with:
`failed to connect to https://10.10.10.10:9345/v1-rke2/readyz: connection refused`

### Cause:
Host firewall blocking TCP port `9345` on the server, or the server IP passed in the join URL was incorrect.

### Check:
```bash
# On the agent:
curl -k https://10.10.10.10:9345/ping

# On the server, verify port 9345 is listening:
sudo ss -tulpn | grep 9345
```

### Fix:
Open port `9345` on the server firewall:
```bash
sudo ufw allow 9345/tcp
```

### Validation:
```bash
curl -k https://10.10.10.10:9345/ping
# Response: "pong"
```

---

## 2. CIS Mode Fails on Startup: Kernel Parameter Validation Error

### Problem:
`rke2-server.service` fails to start:
`fatal: kernel parameter vm.panic_on_oom is invalid. Expected 0, got 1`

### Cause:
RKE2 was configured with a CIS hardening profile, but the host operating system kernel does not meet CIS sysctl recommendations.

### Check:
```bash
sudo journalctl -u rke2-server -e --no-pager | grep -i "kernel parameter"
```

### Fix:
Apply the CIS-compliant sysctl configuration from `configs/cis-sysctl.conf`:
```bash
sudo cp configs/cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
sudo sysctl --system
sudo systemctl restart rke2-server
```

### Validation:
```bash
sudo systemctl is-active rke2-server
# Output: active
```

---

## 3. `rke2-server` Enters CrashLoop: etcd Lock / Address Already In Use

### Problem:
`rke2-server` fails with:
`listen tcp 127.0.0.1:2379: bind: address already in use`

### Cause:
A previous etcd process or aborted cluster instance was not cleanly terminated.

### Check:
```bash
sudo ss -tulpn | grep -E '2379|2380'
```

### Fix:
Kill lingering etcd processes and restart:
```bash
sudo pkill -9 etcd || true
sudo systemctl restart rke2-server
```

### Validation:
```bash
sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes
```
