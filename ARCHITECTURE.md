# Talos Linux Architecture & Security Mechanics

This document provides a technical deep dive into **Talos Linux** internal architecture, security invariants, and declarative machine configuration.

---

## 1. Minimalist Immutable OS Architecture

Unlike general-purpose Linux distributions (which bundle systemd, python, perl, glibc, apt, sshd, bash), Talos runs a custom Go runtime as **PID 1** (`machined`):

```
+-------------------------------------------------------------------------------+
|                            TALOS LINUX HOST NODE                              |
|                                                                               |
|   +-----------------------------------------------------------------------+   |
|   |                         Linux Kernel (Custom OCI)                     |   |
|   +-----------------------------------+-----------------------------------+   |
|                                       |                                       |
|                                       v                                       |
|   +-----------------------------------------------------------------------+   |
|   |                    machined (PID 1 Go Process Manager)                |   |
|   |                                                                       |   |
|   |   +--------------------+  +--------------------+  +---------------+   |   |
|   |   |        apid        |  |       trustd       |  |     udevd     |   |   |
|   |   | gRPC API (50000)   |  | Identity & CA sync |  | Device hotplug|   |   |
|   |   +---------^----------+  +--------------------+  +---------------+   |   |
|   +-------------|---------------------------------------------------------+   |
|                 | (Mutual-TLS gRPC Encrypted Communication)                   |
|                 |                                                             |
|   +-------------v---------------------------------------------------------+   |
|   |                       CONTAINERIZED KUBERNETES                        |   |
|   |   - containerd CRI                                                    |   |
|   |   - kubelet                                                           |   |
|   |   - Static Pods (etcd, kube-apiserver, scheduler, controller-mgr)     |   |
|   +-----------------------------------------------------------------------+   |
+-------------------------------------------------------------------------------+
                                        ^
                                        | Port 50000 (mTLS gRPC via talosctl)
                                        | Port 6443 (kubectl)
+---------------------------------------|---------------------------------------+
|                    OPERATOR WORKSTATION / CI GITOPS                           |
|   - talosctl CLI (uses talosconfig client cert)                               |
|   - kubectl CLI (uses kubeconfig client cert)                                 |
+-------------------------------------------------------------------------------+
```

---

## 2. Security Invariants

1. **Zero Interactive Shells:** No `/bin/bash`, no `/bin/sh`, no python interpreter. An attacker who gains a remote code execution exploit cannot spawn a reverse shell.
2. **Read-Only Root Filesystem:** The root OS image is loaded as a compressed, read-only squashfs image.
3. **No SSH:** System administration is performed exclusively over authenticated, encrypted gRPC APIs (`talosctl`).
4. **Single-Source Configuration:** All OS and cluster states are derived from a cryptographic YAML machine configuration.
