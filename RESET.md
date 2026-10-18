# Minikube Cluster Deletion & Reset Guide

This document describes how to tear down Minikube clusters, destroy sandbox containers or VMs, and purge cached images.

---

## 1. Automated Teardown via `scripts/reset.sh`

```bash
./scripts/reset.sh
```
To purge non-interactively:
```bash
./scripts/reset.sh --force
```

---

## 2. Manual CLI Cleanup

```bash
# 1. Stop the running cluster
minikube stop

# 2. Delete the cluster instance
minikube delete

# 3. Purge all cache and profiles
minikube delete --all --purge
rm -rf "$HOME/.minikube"
```
