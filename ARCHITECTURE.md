# Kubespray Architecture & Automation Mechanics

This document provides a technical deep dive into **Kubespray**, detailing how Ansible playbooks orchestrate the provisioning of upstream Kubernetes across physical or virtual machines.

---

## 1. Automation Flow: Controller vs. Target Fleet

Kubespray operates on an agentless architecture. The controller machine coordinates deployment via SSH:

```
+-------------------------------------------------------------------------------+
|                       ANSIBLE CONTROLLER MACHINE                              |
|                                                                               |
|   +-----------------------------------------------------------------------+   |
|   |   Python 3 + Ansible Core + Kubespray Playbooks                       |   |
|   |   - cluster.yml, scale.yml, reset.yml                                 |   |
|   |   - inventory/mycluster/inventory.ini                                 |   |
|   |   - inventory/mycluster/group_vars/                                   |   |
|   +-----------------------------------+-----------------------------------+   |
+---------------------------------------|---------------------------------------+
                                        |
                 +----------------------+----------------------+
                 | (Parallel SSH Connections: Port 22)          |
                 v                                              v
+----------------------------------+          +----------------------------------+
|      TARGET CONTROL PLANE        |          |       TARGET WORKER NODE         |
|                                  |          |                                  |
|  Roles Executed:                 |          |  Roles Executed:                 |
|  1. bootstrap-os (kernel, swap)  |          |  1. bootstrap-os (kernel, swap)  |
|  2. container-engine (containerd)|          |  2. container-engine (containerd)|
|  3. etcd (standalone / stacked)  |          |  3. kubernetes/node (kubelet)    |
|  4. kubernetes/control-plane     |          |  4. network_plugin (Calico CNI)  |
|  5. network_plugin (Calico CNI)  |          +----------------------------------+
+----------------------------------+
```

---

## 2. Inventory Groups & Node Classification

Kubespray organizes hosts into functional clusters using standard Ansible inventory groups:

```ini
[all]
k8s-control-01 ansible_host=10.10.10.10 ip=10.10.10.10
k8s-worker-01  ansible_host=10.10.10.11 ip=10.10.10.11
k8s-worker-02  ansible_host=10.10.10.12 ip=10.10.10.12

[kube_control_plane]
k8s-control-01

[etcd]
k8s-control-01

[kube_node]
k8s-worker-01
k8s-worker-02

[k8s_cluster:children]
kube_control_plane
kube_node
```

### Group Semantics:
- **`kube_control_plane`:** Nodes running `kube-apiserver`, `kube-controller-manager`, and `kube-scheduler`.
- **`etcd`:** Nodes hosting etcd cluster members (should be 1, 3, or 5 nodes to maintain Raft quorum).
- **`kube_node`:** Worker nodes executing user application workloads.
- **`k8s_cluster:children`:** Meta-group inheriting cluster-wide variables (CNI, Kubernetes version, DNS domain).
