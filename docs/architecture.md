# Kubespray Architecture Deep Dive

This document details Ansible role execution, task tagging, and handler mechanics in Kubespray.

---

## 1. Playbook Role Execution Sequence

When `cluster.yml` runs, it executes the following roles sequentially across inventory groups:
1. **`facts`**: Gathers system facts and detects OS distribution.
2. **`download`**: Pre-downloads container images and binaries.
3. **`bootstrap-os`**: Configures swapoff, sysctl forwarding, and kernel modules (`br_netfilter`, `overlay`).
4. **`container-engine`**: Installs containerd or CRI-O with systemd cgroup drivers.
5. **`etcd`**: Bootstraps etcd cluster on nodes belonging to the `[etcd]` inventory group.
6. **`kubernetes/control-plane`**: Configures static pods for kube-apiserver, kube-scheduler, and kube-controller-manager.
7. **`kubernetes/node`**: Configures kubelet and kube-proxy on all `[kube_node]` hosts.
8. **`network_plugin`**: Deploys Calico, Cilium, or Flannel DaemonSets.
