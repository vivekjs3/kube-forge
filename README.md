# Talos Linux Installation Laboratory 🛡️⚡

> **Modern Immutable, API-Driven Operating System Designed Exclusively for Kubernetes**  
> *Target Audience:* Security Engineers, Platform Architects, GitOps Bare-Metal Practitioners  
> *Target OS:* Talos Linux v1.8+ (Appliance OS - No Ubuntu/Debian/RHEL underneath)  
> *Target Kubernetes Version:* v1.31.x / v1.30.x

---

## 🎯 What is Talos Linux?

**Talos Linux** (developed by Sidero Labs) is not just another Kubernetes installer. It is a **purpose-built, minimal, immutable Linux operating system** designed from scratch solely to host Kubernetes.

### The Paradigm Shift:
- 🚫 **No Shell, No Bash, No SSH:** There is literally no `/bin/sh`, no SSH daemon, and no interactive console. Attack surface is mathematically minimized.
- 🔒 **Immutable Read-Only Filesystem:** The root filesystem is mounted read-only squashfs. System files cannot be modified, corrupted, or tampered with by malware.
- 📡 **100% API-Driven Management:** The entire operating system is managed over mutual-TLS gRPC APIs via the `talosctl` CLI.
- 📄 **Declarative Machine Configuration:** Every aspect of the OS (hostname, static IPs, disk partitions, kernel modules, sysctl, Kubernetes version) is expressed in a single declarative YAML file.
- ⚡ **Single-Command Atomic Upgrades:** Upgrading Talos Linux or Kubernetes is an atomic, zero-downtime operation triggered via API.

---

## 🏗️ Laboratory Topology

```
                   Management Machine / Operator Workstation
                                      |
              (mTLS gRPC via talosctl on Port 50000 / kubectl 6443)
                                      |
         =============================+=============================
                          Lab Network (10.10.10.0/24)
                                      |
         +----------------------------+----------------------------+
         |                                                         |
         v                                                         v
+-------------------------+                               +-------------------------+
|     talos-control-01    |                               |      talos-worker-01    |
| IP: 10.10.10.10         |                               | IP: 10.10.10.11         |
| Role: Control Plane     |                               | Role: Worker Node       |
| OS: Talos Linux         |                               | OS: Talos Linux         |
| 2 vCPU, 4 GB RAM        |                               | 2 vCPU, 2 GB RAM        |
+-------------------------+                               +-------------------------+
```

---

## 📋 Step-by-Step Installation Workflow

Follow the numbered scripts in `scripts/`:

```bash
# Step 1: Install talosctl and kubectl on your workstation
sudo ./scripts/01-prerequisites.sh

# Step 2: Generate declarative machine configurations (controlplane, worker, talosconfig)
./scripts/02-generate-configs.sh

# Step 3: Apply control plane configuration to the first node
./scripts/03-apply-controlplane.sh 10.10.10.10

# Step 4: Bootstrap etcd and initialize Kubernetes on control plane
./scripts/04-bootstrap-cluster.sh 10.10.10.10

# Step 5: Apply worker configuration to worker node(s)
./scripts/05-apply-worker.sh 10.10.10.11

# Step 6: Validate node readiness, retrieve kubeconfig, and deploy test workload
./scripts/06-validate.sh 10.10.10.10
```

---

## 🔄 Reset & Cleanup

To completely wipe and reset a Talos node over the gRPC API:
```bash
./scripts/reset.sh <NODE_IP>
```

---

## 📖 Deep Dives

- [ARCHITECTURE.md](file:///home/vivek/k8s-proj/ARCHITECTURE.md) — Immutability, `machined` PID 1, gRPC API (Port 50000), and PKI.
- [PREREQUISITES.md](file:///home/vivek/k8s-proj/PREREQUISITES.md) — Booting Talos ISO, hardware specs, and network requirements.
- [TROUBLESHOOTING.md](file:///home/vivek/k8s-proj/TROUBLESHOOTING.md) — `talosctl dmesg`, maintenance mode, and logs inspection.
- [docs/networking.md](file:///home/vivek/k8s-proj/docs/networking.md) — Virtual IP (VIP), CNI plugins, and network configuration.
