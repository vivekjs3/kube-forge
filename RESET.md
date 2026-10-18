# Kubespray Teardown & Cluster Reset Guide

This document describes how to execute Kubespray's built-in teardown playbook to wipe all installed Kubernetes components from target nodes.

---

## 1. Automated Reset Script

```bash
./scripts/reset.sh
```
To run non-interactively without prompt:
```bash
./scripts/reset.sh --force
```

---

## 2. Running `reset.yml` Directly via Ansible

```bash
source venv/bin/activate
ansible-playbook -i inventory/mycluster/inventory.ini kubespray/reset.yml \
    -b -v \
    -e reset_confirmation=yes
```

### What `reset.yml` Does:
1. Drains and deletes worker nodes from the API server.
2. Stops and removes `kubelet`, `containerd`, and `etcd` services.
3. Deletes `/etc/kubernetes`, `/var/lib/etcd`, `/var/lib/kubelet`, `/etc/cni/net.d`.
4. Flushes host iptables and IPVS rules.
5. Deletes virtual network interfaces (`cni0`, `flannel.1`, `calico*`).
