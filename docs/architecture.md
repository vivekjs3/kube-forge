# Talos Linux Architecture Deep Dive

This document details the mechanics of Talos Linux system services, security guarantees, and machine config schemas.

---

## 1. Process Hierarchy

In Talos Linux:
- The Linux kernel boots directly to `/sbin/init` which is a symlink to `/bin/machined`.
- `machined` acts as PID 1 and supervises:
  - `apid`: Authenticated gRPC server on port 50000.
  - `trustd`: Distributes TLS secrets across the cluster.
  - `containerd`: Container runtime.
  - `kubelet`: Node agent.
- There are no cron daemons, no syslog daemons, and no user sessions.
