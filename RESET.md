# Talos Linux Node Teardown & Reset Guide

This document describes how to execute a complete remote wipe and reset of a Talos Linux node via the `talosctl` API.

---

## 1. Automated Reset Script

```bash
./scripts/reset.sh <NODE_IP>
```
To run non-interactively without prompt:
```bash
./scripts/reset.sh <NODE_IP> --force
```

---

## 2. Manual API Reset Command

To wipe all partitions, delete etcd data, and reboot the machine back into maintenance mode:

```bash
talosctl reset \
  --nodes 10.10.10.10 \
  --endpoints 10.10.10.10 \
  --graceful=false \
  --reboot
```

### What Happens:
1. `machined` unmounts all container volumes.
2. The system formats and wipes the local installation disk (`/dev/sda` or `/dev/nvme0n1`).
3. The machine reboots back into the initial Talos installation environment.
