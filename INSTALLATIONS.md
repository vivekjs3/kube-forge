# Installation Methods & Selection Guide

`kube-forge` organizes each Kubernetes installation paradigm on dedicated, isolated Git branches. This document provides a side-by-side technical evaluation, hardware requirements, architectural differences, and a decision tree to help you select the ideal method.

---

## 1. Branch Registry & Comparison Matrix

| Distribution / Method | Branch | Target Complexity | Architecture Type | Primary Use Case |
|---|---|---|---|---|
| **Kubernetes The Hard Way** | [`hardway`](#1-kubernetes-the-hard-way-hardway) | **Advanced** | Raw Binaries & Systemd Units | Mastering deep internals, PKI, manual systemd units |
| **Kubeadm** | [`kubeadm`](#2-kubeadm-kubeadm) | **Intermediate** | Static Pods & Systemd Kubelet | Official CNCF standard for bare-metal & production |
| **K3s** | [`k3s`](#3-k3s-k3s) | **Beginner** | Single Compact Binary | Edge, IoT, single-node labs, lightweight CI runners |
| **RKE2 (Rancher Government)**| [`rke2`](#4-rke2-rke2) | **Intermediate** | Packaged Systemd & Embedded CRI | CIS-hardened, defense/enterprise regulated workloads |
| **Minikube** | [`minikube`](#5-minikube-minikube) | **Beginner** | Single-Node VM / Docker Container | Developer workstation sandbox & rapid experimentation |
| **MicroK8s** | [`microk8s`](#6-microk8s-microk8s) | **Beginner** | Canonical Snap Package | Zero-ops workstation/edge clustering with instant addons |
| **Kubespray** | [`kubespray`](#7-kubespray-kubespray) | **Advanced** | Ansible Orchestrated Automation | Automated multi-node bare-metal fleet deployment |
| **Talos Linux** | [`talos`](#8-talos-linux-talos) | **Advanced** | Immutable API-Managed OS | Modern security-first, declarative GitOps bare-metal |

---

## 2. In-Depth Method Profiles

### 1. Kubernetes The Hard Way (`hardway`)
- **Git Branch:** `hardway`
- **What it is:** Manual, zero-abstraction bootstrap of all Kubernetes components from upstream tarball binaries.
- **How it runs:** Individual Linux `systemd` services for `etcd`, `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `kubelet`, and `kube-proxy`.
- **Key Concepts Learned:** Manual PKI generation with `cfssl` / `openssl`, kubeconfig construction, RBAC for kube-apiserver to kubelet, overlay routing.
- **Resource Requirement:** 2 vCPU, 4 GB RAM per control plane; 1 vCPU, 2 GB RAM per worker.
- **When to choose:** You want complete technical understanding of how Kubernetes binaries interact without automated helpers.

### 2. Kubeadm (`kubeadm`)
- **Git Branch:** `kubeadm`
- **What it is:** The official upstream Kubernetes lifecycle bootstrapper.
- **How it runs:** `kubelet` runs as a system service; `etcd`, `kube-apiserver`, `kube-scheduler`, and `kube-controller-manager` run as **Static Pods** managed directly by the local kubelet.
- **Key Concepts Learned:** Declarative `KubeadmConfig`, bootstrap tokens, static pod manifests in `/etc/kubernetes/manifests/`, modular CNI injection.
- **Resource Requirement:** 2 vCPU, 2 GB RAM per control plane; 1 vCPU, 2 GB RAM per worker.
- **When to choose:** You are designing standard bare-metal production clusters or enterprise platforms.

### 3. K3s (`k3s`)
- **Git Branch:** `k3s`
- **What it is:** Highly lightweight, certified Kubernetes distribution engineered by SUSE / Rancher for edge and resource-constrained nodes.
- **How it runs:** Single executable binary packaging the control plane, worker agent, containerd, and Flannel. Uses SQLite by default for single node, or embedded etcd for HA.
- **Key Concepts Learned:** Lightweight datastores (Kine/SQLite), vendored runtime, battery-included ingress (Traefik) and local storage (Local-Path).
- **Resource Requirement:** 1 vCPU, 512 MB - 1 GB RAM.
- **When to choose:** Edge deployments, local development, Raspberry Pi/ARM clusters, or ultra-fast spin-up testing.

### 4. RKE2 (`rke2`)
- **Git Branch:** `rke2`
- **What it is:** Rancher's next-generation distribution combining K3s packaging simplicity with strict enterprise CIS compliance.
- **How it runs:** Managed via `rke2-server` and `rke2-agent` systemd units. Embeds hardened containerd, etcd, and Canal/Cilium CNI.
- **Key Concepts Learned:** Automated CIS Benchmark profile enforcement, FIPS 140-2 compliance, air-gap packaging, security token joins.
- **Resource Requirement:** 2 vCPU, 4 GB RAM per server; 1 vCPU, 2 GB RAM per agent.
- **When to choose:** Production environments demanding compliance with US Government / DoD or strict enterprise security baselines.

### 5. Minikube (`minikube`)
- **Git Branch:** `minikube`
- **What it is:** Tool for running local single-node Kubernetes clusters on a laptop or workstation.
- **How it runs:** Inside a local Docker container, Podman container, or hypervisor VM (KVM, VirtualBox, QEMU).
- **Key Concepts Learned:** Driver management, instant addons (`minikube addons enable ingress`), tunnel networking.
- **Resource Requirement:** 2 vCPU, 2 GB RAM.
- **When to choose:** Day-to-day developer application testing. *Note: Minikube is not intended for bare-metal multi-node production.*

### 6. MicroK8s (`microk8s`)
- **Git Branch:** `microk8s`
- **What it is:** Zero-ops, lightweight Kubernetes package delivered through Canonical's `snap` universal package manager.
- **How it runs:** Contained within snap user-space with integrated dqlite datastore for multi-node clustering.
- **Key Concepts Learned:** Snap isolation, built-in feature toggles (`microk8s enable dns ingress cert-manager`).
- **Resource Requirement:** 2 vCPU, 2 GB RAM.
- **When to choose:** Fast setup on Ubuntu workstations, edge appliances, or single-command local multi-node clusters.

### 7. Kubespray (`kubespray`)
- **Git Branch:** `kubespray`
- **What it is:** An Ansible-based automation suite for provisioning upstream Kubernetes clusters across diverse Linux distributions.
- **How it runs:** Ansible playbooks orchestrating SSH execution, package installation, etcd clustering, and CNI provisioning.
- **Key Concepts Learned:** Infrastructure as Code (IaC) configuration management, declarative inventories, cluster scaling, and rolling upgrades.
- **Resource Requirement:** Ansible controller host + standard target nodes (2 vCPU, 4 GB RAM).
- **When to choose:** Automated deployment across heterogeneous Linux fleets, physical data centers, or hybrid cloud nodes.

### 8. Talos Linux (`talos`)
- **Git Branch:** `talos`
- **What it is:** A modern, purpose-built immutable Linux distribution designed exclusively to host Kubernetes.
- **How it runs:** No shell, no SSH, no systemd. Managed entirely through a secured gRPC API (`talosctl`) with declarative YAML machine configurations.
- **Key Concepts Learned:** Immutable infrastructure, ephemeral OS nodes, API-driven platform operations, attack-surface elimination.
- **Resource Requirement:** 2 vCPU, 2 GB RAM per node.
- **When to choose:** Modern security-conscious bare-metal environments practicing strict GitOps and immutable infrastructure.

---

## 3. Decision Tree: Which Method Should You Choose?

```
                        What is your primary objective?
                                       |
          +----------------------------+----------------------------+
          |                                                         |
 [Education & Deep Internals]                            [Running Real Workloads]
          |                                                         |
   Master internals?                                How many nodes / what scale?
    /           \                                         /               \
 [YES]          [NO]                              [Single Node Dev]     [Multi-Node Cluster]
   |              |                                     |                        |
hardway        kubeadm                                  |             What is your priority?
                                            Workstation or Edge?      /         |          \
                                              /             \        /          |           \
                                         [Laptop]          [Edge] [Standard] [Security] [Immutable]
                                            |                |        |         |           |
                                         minikube           k3s    kubeadm    rke2        talos
                                         microk8s                 kubespray
```

---

## 4. Operating System Support Matrix

| OS / Distribution | `kubeadm` | `k3s` | `rke2` | `hardway` | `minikube` | `microk8s` | `kubespray` | `talos` |
|---|---|---|---|---|---|---|---|---|
| **Ubuntu 22.04 LTS (Jammy)** | Verified | Verified | Verified | Verified | Verified | Verified | Verified | N/A (OS-level) |
| **Ubuntu 24.04 LTS (Noble)** | Verified | Verified | Verified | Verified | Verified | Verified | Verified | N/A (OS-level) |
| **Debian 12 (Bookworm)** | Roadmap | Planned | Planned | Planned | Verified | Planned | Planned | N/A (OS-level) |
| **Rocky / AlmaLinux 9** | Roadmap | Planned | Planned | Planned | Verified | N/A | Planned | N/A (OS-level) |
| **Talos Linux OS** | N/A | N/A | N/A | N/A | N/A | N/A | N/A | Dedicated OS |

---

## 5. How to Switch Branches

To enter any lab, ensure your local workspace is clean and check out the target branch:

```bash
# Example: Switch to the kubeadm laboratory
git checkout kubeadm

# Example: Switch to Kubernetes The Hard Way
git checkout hardway

# Example: Switch to K3s
git checkout k3s
```
