# Kubernetes The Hard Way: Architectural Deep Dive

This document details the mechanics of manually provisioning etcd, bootstrapping the control plane, and orchestrating native systemd services.

---

## 1. Zero-Abstraction Execution Model

In this deployment paradigm:
- Every binary is compiled upstream by the Kubernetes project.
- There are no container engines involved in running `etcd` or `kube-apiserver`.
- All operational flags (e.g. `--client-ca-file`, `--etcd-servers`, `--service-cluster-ip-range`, `--cluster-cidr`) are defined explicitly in `/etc/systemd/system/*.service` files.

---

## 2. Encryption at Rest

In a production cluster, secrets in `etcd` should be encrypted rather than stored in plaintext. In this lab, we configure `/var/lib/kubernetes/encryption-config.yaml` using the `aescbc` provider, passing `--encryption-provider-config` to `kube-apiserver`.
