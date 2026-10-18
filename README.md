# kube-forge ⚒️

> **The Kubernetes Installation Laboratory and Framework**  
> *A clean, beginner-friendly, and technically deep repository for mastering, deploying, and validating Kubernetes across bare-metal, virtualized, and edge Linux infrastructure.*

---

## 🧭 Overview

**kube-forge** is not a generic Kubernetes tutorial. It is a comprehensive **Installation Laboratory and Framework** engineered to demystify how Kubernetes clusters are bootstrapped, configured, secured, and maintained from bare silicon or virtual machines up.

Whether you are a Linux administrator learning container orchestration, an SRE designing resilient enterprise clusters, or a Platform Engineer automating bare-metal infrastructure, **kube-forge** teaches you:

- 🧱 **WHAT** is being installed at each phase.
- 🎯 **WHY** each kernel parameter, certificate, daemon, and manifest is required.
- 📡 **HOW** the components communicate internally across mTLS and network boundaries.
- 🔍 **WHAT** happens under the hood during control-plane and worker initialization.
- ✅ **HOW** to validate the installation with deep health checks and test workloads.
- 🛠️ **HOW** to troubleshoot node, runtime, CNI, and DNS failures.
- 🔄 **HOW** to cleanly uninstall and reset nodes to pristine condition.

---

## 🌿 Branching Architecture & Laboratory Matrix

To keep implementations clean, modular, and unpolluted, **each installation method lives on its own dedicated Git branch**.

The `main` branch functions as the architectural gateway and documentation hub. To enter a specific installation laboratory, simply check out its branch:

| Installation Method | Branch | Difficulty | Architectural Paradigm | Primary Use Case |
|---|---|---|---|---|
| **[Kubernetes The Hard Way](https://github.com/vivekjs3/kube-forge/tree/hardway)** | [`hardway`](#) | **Advanced** | Raw Binaries & Systemd Units | Complete deconstruction, manual PKI, zero-abstraction learning |
| **[Kubeadm](https://github.com/vivekjs3/kube-forge/tree/kubeadm)** | [`kubeadm`](#) | **Intermediate** | Static Pods & Systemd Kubelet | Official CNCF reference standard for production bare-metal |
| **[K3s](https://github.com/vivekjs3/kube-forge/tree/k3s)** | [`k3s`](#) | **Beginner** | Single Packaged Binary | Edge computing, IoT, lightweight single-node labs, fast CI |
| **[RKE2 (Rancher Government)](https://github.com/vivekjs3/kube-forge/tree/rke2)** | [`rke2`](#) | **Intermediate** | Hardened Systemd & Embedded CRI | CIS benchmark hardened, defense & enterprise regulated workloads |
| **[Minikube](https://github.com/vivekjs3/kube-forge/tree/minikube)** | [`minikube`](#) | **Beginner** | Single-Node VM / Docker Driver | Local developer workstation sandbox & rapid experimentation |
| **[MicroK8s](https://github.com/vivekjs3/kube-forge/tree/microk8s)** | [`microk8s`](#) | **Beginner** | Canonical Snap Package | Zero-ops workstation/edge clustering with instant addons |
| **[Kubespray](https://github.com/vivekjs3/kube-forge/tree/kubespray)** | [`kubespray`](#) | **Advanced** | Ansible Automation Playbooks | Production bare-metal fleet orchestration across multiple nodes |
| **[Talos Linux](https://github.com/vivekjs3/kube-forge/tree/talos)** | [`talos`](#) | **Advanced** | Immutable API-Managed OS | Modern security-first, declarative GitOps bare-metal |

```bash
# Example: enter the kubeadm laboratory
git checkout kubeadm

# Example: enter Kubernetes The Hard Way
git checkout hardway
```

---

## 🏛️ High-Level System Architecture

Kubernetes separates its responsibilities into the **Control Plane** (cluster brain and state store) and the **Worker Fleet** (execution runtime):

```
                                  KUBERNETES CLUSTER
  +---------------------------------------------------------------------------------+
  |                             CONTROL PLANE NODE(S)                               |
  |                                                                                 |
  |      +------------------+    +----------------------+                           |
  |      |  kube-scheduler  |    | kube-controller-mgr  |                           |
  |      +--------+---------+    +----------+-----------+                           |
  |               |                         |                                       |
  |               v                         v                                       |
  |       +---------------+       +-------------------+                             |
  |       | kube-apiserver| <---> |       etcd        | (Port 2379/2380)            |
  |       |  (Port 6443)  |       +-------------------+                             |
  |       +-------+-------+                                                         |
  +---------------|-----------------------------------------------------------------+
                  |
                  | Encrypted mTLS (Port 6443)
                  |
  +---------------|-----------------------------------------------------------------+
  |               v                 WORKER NODE(S)                                  |
  |    +--------------------+    +--------------------+    +--------------------+   |
  |    |      kubelet       |    |     kube-proxy     |    |      CoreDNS       |   |
  |    |    (Port 10250)    |    | (iptables / IPVS)  |    |     (Port 53)      |   |
  |    +----------+---------+    +--------------------+    +--------------------+   |
  |               |                                                                 |
  |               v (gRPC Unix Socket)                                              |
  |    +-----------------------------------------------+                            |
  |    |  Container Runtime Interface (containerd/CRI) |                            |
  |    +----------------------+------------------------+                            |
  |                           |                                                     |
  |                           v (veth / eBPF / VXLAN)                               |
  |    +-----------------------------------------------+                            |
  |    |  Container Network Interface (Calico/Flannel) |                            |
  |    +-----------------------------------------------+                            |
  |                                                                                 |
  |    +-----------------------+    +-----------------------+                       |
  |    |  Pod Sandbox A (veth) |    |  Pod Sandbox B (veth) |                       |
  |    +-----------------------+    +-----------------------+                       |
  +---------------------------------------------------------------------------------+
```

---

## 🐧 Operating System Support Matrix

| Operating System | Version | `kubeadm` | `k3s` | `rke2` | `hardway` | `minikube` | `microk8s` | `kubespray` | `talos` |
|---|---|---|---|---|---|---|---|---|---|
| **Ubuntu Server** | 22.04 LTS (Jammy) | Verified | Verified | Verified | Verified | Verified | Verified | Verified | N/A |
| **Ubuntu Server** | 24.04 LTS (Noble) | Verified | Verified | Verified | Verified | Verified | Verified | Verified | N/A |
| **Debian** | 12 (Bookworm) | Planned | Planned | Planned | Planned | Verified | Planned | Planned | N/A |
| **Rocky / AlmaLinux**| 9.x | Planned | Planned | Planned | Planned | Verified | N/A | Planned | N/A |
| **Talos Linux OS** | 1.8+ | N/A | N/A | N/A | N/A | N/A | N/A | N/A | Dedicated OS |

---

## 📋 Standard Laboratory Topology

Unless specified otherwise, multi-node laboratories in `kube-forge` utilize a predictable 3-node topology on a private subnet:

```
Control Plane:
  k8s-control-01  |  10.10.10.10  |  2 vCPU, 4 GB RAM  |  Ubuntu 24.04 LTS

Workers:
  k8s-worker-01   |  10.10.10.11  |  2 vCPU, 2 GB RAM  |  Ubuntu 24.04 LTS
  k8s-worker-02   |  10.10.10.12  |  2 vCPU, 2 GB RAM  |  Ubuntu 24.04 LTS
```

---

## 📦 Standard Implementation Branch Structure

Every implementation branch follows an identical, transparent layout:

```text
<branch>/
├── README.md               # Quickstart, step-by-step workflow, topology
├── ARCHITECTURE.md         # Component diagrams and data paths specific to this method
├── PREREQUISITES.md        # Hardware, OS, kernel, port, and network requirements
├── TROUBLESHOOTING.md      # Matrix of known failures, diagnostic commands, and fixes
├── RESET.md                # Teardown, uninstallation, and node recovery instructions
│
├── docs/                   # Detailed documentation
│   ├── architecture.md     # Deep dive into how this distribution functions
│   ├── networking.md       # CNI, service routing, and packet flow details
│   ├── components.md       # Binaries, systemd units, configuration files
│   └── validation.md       # Verification procedures & expected outputs
│
├── scripts/                # Numbered, idempotent, educational shell scripts
│   ├── 01-prerequisites.sh
│   ├── 02-system-config.sh
│   ├── 03-container-runtime.sh
│   ├── 04-install-kubernetes.sh
│   ├── 05-init-cluster.sh
│   ├── 06-install-cni.sh
│   ├── 07-join-workers.sh
│   └── 08-validate.sh
│
├── configs/                # Sample configuration templates (*.yaml.example, *.toml)
├── examples/               # Test workloads (nginx deployment, service, ingress test)
└── tests/                  # Verification and diagnostic test runners
```

---

## 🔒 Security & Code Hygiene

- **Zero Secrets Committed:** All configuration files use `.example` templates. Certificates, keys, tokens, and credentials are never stored in git.
- **Idempotency:** Scripts verify current system state prior to mutating files or kernel settings.
- **Explicit Versioning:** We pin tested versions of Kubernetes and components (e.g. Kubernetes `v1.31.x`) rather than installing moving `latest` targets.
- **Safety First:** Reset scripts require explicit user confirmation before tearing down configurations or packages.

---

## 📚 Deep-Dive Documentation Index

Explore the conceptual documentation housed in `docs/`:

- [**Kubernetes Internals Deep Dive**](file:///home/vivek/k8s-proj/docs/kubernetes-internals.md) — What runs where, how components communicate, and the pod creation sequence.
- [**Networking Deep Dive**](file:///home/vivek/k8s-proj/docs/networking-deep-dive.md) — Underlay vs. Overlay, CNI plugins, packet encapsulation, and Service routing.
- [**Operating System Preparation**](file:///home/vivek/k8s-proj/docs/operating-systems.md) — Kernel modules, sysctl parameters, swap mechanics, and firewall ports.
- [**Security Baseline & PKI**](file:///home/vivek/k8s-proj/docs/security-baseline.md) — Certificate authorities, SAN requirements, RBAC, and node authorization.
- [**Laboratory Topologies**](file:///home/vivek/k8s-proj/docs/lab-topologies.md) — Reference hardware, network layouts, and `/etc/hosts` configurations.
- [**Installation Selection Guide**](file:///home/vivek/k8s-proj/INSTALLATIONS.md) — Comprehensive comparison and decision tree.

---

## 🤝 Contributing

Contributions to `kube-forge` are warmly welcomed! Please read our [**Contributing Guide**](file:///home/vivek/k8s-proj/CONTRIBUTING.md) and [**Agent Operating Guide**](file:///home/vivek/k8s-proj/AGENTS.md) before submitting pull requests.

---

## 📄 License

This project is licensed under the [MIT License](file:///home/vivek/k8s-proj/LICENSE).
