# Talos Linux Troubleshooting Guide

Because Talos contains no interactive shell or SSH daemon, all debugging and diagnostic inspections are performed using **`talosctl`** over mutual-TLS gRPC APIs.

---

## 1. Remote Diagnostics Without SSH

Use these commands to inspect node state remotely:

```bash
# 1. Real-time Interactive Terminal Dashboard (TUI)
talosctl -n 10.10.10.10 dashboard

# 2. Kernel dmesg logs
talosctl -n 10.10.10.10 dmesg

# 3. Kubelet container logs
talosctl -n 10.10.10.10 logs kubelet

# 4. etcd service logs
talosctl -n 10.10.10.10 logs etcd

# 5. List running containers
talosctl -n 10.10.10.10 containers

# 6. Check memory and system health
talosctl -n 10.10.10.10 memory
talosctl -n 10.10.10.10 health
```

---

## 2. Node Stuck in Maintenance Mode

### Problem:
Node does not start Kubernetes and reports `Stage: Maintenance`.

### Cause:
1. No machine configuration has been applied yet.
2. The installation disk specified in `install.disk` does not exist on the target machine (e.g. `/dev/sda` vs `/dev/nvme0n1`).

### Check:
```bash
talosctl -n 10.10.10.10 disks
```

### Fix:
Update the `disk` selector in `controlplane.yaml` or `worker.yaml` with the exact device name found above, then re-apply:
```bash
talosctl apply-config --insecure -n 10.10.10.10 --file controlplane.yaml
```

---

## 3. etcd Bootstrap Failed / Timed Out

### Problem:
`talosctl bootstrap` returns an error or hangs.

### Fix:
Ensure `bootstrap` is run **only once** on the primary control plane node, and verify that port `50000` is open:
```bash
talosctl -n 10.10.10.10 service etcd
```
