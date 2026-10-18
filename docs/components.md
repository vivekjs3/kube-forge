# Kubeadm Component Breakdown

This document enumerates the binaries, services, and containers configured by `kubeadm`.

---

## 1. Host-Level Binaries (Managed by systemd)

- **`kubelet` (`/usr/bin/kubelet`):**
  - Manages pods and containers on the local machine.
  - Configured via `/var/lib/kubelet/config.yaml`.
  - Service unit: `/lib/systemd/system/kubelet.service` with drop-in `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf`.
- **`containerd` (`/usr/bin/containerd`):**
  - High-performance container runtime.
  - Listens on `/run/containerd/containerd.sock`.
  - Configured via `/etc/containerd/config.toml`.
- **`kubectl` (`/usr/bin/kubectl`):**
  - Command-line utility for communicating with the cluster API server.
- **`kubeadm` (`/usr/bin/kubeadm`):**
  - Bootstrap CLI used to execute `init`, `join`, `upgrade`, and `reset`.

---

## 2. Containerized Control Plane (Static Pods)

- **`kube-apiserver`:** Exposes the Kubernetes API on `0.0.0.0:6443`.
- **`kube-controller-manager`:** Reconciles desired vs actual state for deployments, nodes, endpoints.
- **`kube-scheduler`:** Computes node assignment for unscheduled pods.
- **`etcd`:** Raft-based distributed key-value store running on `127.0.0.1:2379` with client TLS authentication.

---

## 3. Cluster Add-ons (In-Cluster DaemonSets & Deployments)

- **`kube-proxy` (DaemonSet):** Runs on all nodes to route Service traffic via iptables.
- **`coredns` (Deployment):** Internal DNS server providing cluster service resolution (`kube-dns`).
- **CNI Plugin (DaemonSet):** Calico (`calico-node`) or Flannel (`kube-flannel-ds`).
