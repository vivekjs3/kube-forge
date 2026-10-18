# Kubernetes The Hard Way: Components Breakdown

This document enumerates the raw binaries, service definitions, and configuration files installed during the manual bootstrap.

---

## 1. Binaries

| Binary | Source | Location |
|---|---|---|
| `etcd` & `etcdctl` | GitHub etcd-io releases | `/usr/local/bin/` |
| `kube-apiserver` | dl.k8s.io | `/usr/local/bin/` |
| `kube-controller-manager` | dl.k8s.io | `/usr/local/bin/` |
| `kube-scheduler` | dl.k8s.io | `/usr/local/bin/` |
| `kubectl` | dl.k8s.io | `/usr/local/bin/` |
| `kubelet` | dl.k8s.io | `/usr/local/bin/` |
| `kube-proxy` | dl.k8s.io | `/usr/local/bin/` |
| `containerd` & `runc` | containerd / opencontainers | `/usr/local/bin/` |
| `bridge`, `loopback` | containernetworking/plugins | `/opt/cni/bin/` |
