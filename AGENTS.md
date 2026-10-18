# AGENTS.md — Platform Agent Operating Guide for kube-forge

Welcome to **kube-forge: The Kubernetes Installation Laboratory and Framework**.

This repository is designed for both human platform engineers and autonomous AI agents. This document defines the engineering standards, architecture constraints, and behavioral contracts required when contributing to or executing workflows within `kube-forge`.

---

## 1. Repository Identity & Core Mission

- **Project Name:** `kube-forge`
- **Remote:** `https://github.com/vivekjs3/kube-forge.git`
- **Purpose:** An educational and production-grade Kubernetes Installation Laboratory and Framework that demonstrates, deconstructs, and implements diverse Kubernetes deployment paradigms on bare-metal and Linux virtualized infrastructure.
- **Target Audience:** From Linux beginners to Principal Platform/SRE Engineers.
- **Core Mantra:** *Do not merely script installation. Explain WHAT is installed, WHY it is required, HOW components communicate internally, HOW to validate, and HOW to cleanly recover or reset.*

---

## 2. Strict Branching Architecture

To maintain clarity and prevent cross-contamination of deployment paradigms, **implementations are strictly separated by branch**.

### Branch Registry
| Branch Name | Paradigm / Distribution | Target Audience | Primary Focus |
|---|---|---|---|
| `main` | **Hub & Architecture Gateway** | All | Documentation, decision trees, conceptual blueprints, agent skills. No installation scripts! |
| `kubeadm` | **Standard Upstream Bootstrapper** | Intermediate | Upstream reference standard, containerd, kubeadm init/join, CNI. |
| `k3s` | **Lightweight Packaged Kubernetes** | Beginner | Single binary, embedded SQLite/etcd, low-footprint, edge/dev. |
| `rke2` | **Security-Hardened Enterprise** | Intermediate | Rancher Government, FIPS/CIS compliant, embedded etcd, canal/cilium. |
| `hardway` | **Kubernetes The Hard Way** | Advanced | Manual bootstrap: CA, PKI certificates, etcd, binaries, systemd units, deep internals. |
| `minikube` | **Local Developer Sandbox** | Beginner | Local single-node VM/Docker driver, addons, rapid prototyping. |
| `microk8s` | **Zero-Ops Snap Distribution** | Beginner | Canonical single/multi-node snap, built-in ingress/storage/DNS addons. |
| `kubespray` | **Ansible Bare-Metal Automation** | Advanced | Production-grade automation, multi-OS, declarative YAML inventories. |
| `talos` | **Immutable Linux Appliance OS** | Advanced | API-driven immutable OS, zero SSH, declarative machine config. |

> [!IMPORTANT]
> - **Never mix distribution scripts into `main`.** The `main` branch is purely pedagogical, structural, and navigational.
> - **Branch names must remain exact and lowercase:** `kubeadm`, `k3s`, `rke2`, `hardway`, `minikube`, `microk8s`, `kubespray`, `talos`.
> - Do not invent arbitrary branch names like `feature/kubeadm-install` or `dev-test` unless explicitly authorized.

---

## 3. Engineering & Scripting Rules

When authoring or modifying code within any branch, adhere strictly to these rules:

### A. Modular, Numbered Scripts
Do **not** build monolithic `install.sh` scripts. Deconstruct tasks into numbered, single-responsibility scripts:
```
scripts/
├── 01-prerequisites.sh       # Kernel checks, CPU/RAM validation, user permissions
├── 02-system-config.sh       # Kernel modules, sysctl, swapoff, firewall ports
├── 03-container-runtime.sh   # Container runtime (e.g. containerd/CRI-O) or distro binaries
├── 04-install-kubernetes.sh  # Repo setup, package installation (kubelet, kubeadm, kubectl)
├── 05-init-cluster.sh        # Control-plane bootstrap / initialization
├── 06-install-cni.sh         # Pod Network implementation (Calico, Flannel, Cilium)
├── 07-join-workers.sh        # Worker node joining instructions & token generation
└── 08-validate.sh            # End-to-end cluster, network, and workload verification
```

### B. Command Transparency
- Every command must be readable and educational.
- Avoid burying crucial commands inside multi-layered shell functions or opaque wrapper abstractions.
- Print clear, color-coded status messages:
  - `[INFO]` for informational milestones
  - `[WARN]` for non-fatal considerations
  - `[SUCCESS]` for verified steps
  - `[ERROR]` for actionable failures

### C. State Detection & Idempotency
- Scripts must check if an operation is already completed before executing destructive modifications.
- Check before appending to `/etc/hosts`, `/etc/sysctl.d/`, or `/etc/modules-load.d/`.
- Always back up system configuration files before editing (e.g., `cp /etc/sysctl.conf /etc/sysctl.conf.bak.$(date +%F)`).

### D. Zero Secrets & Safety Constraints
- **NEVER commit sensitive data:** tokens, private keys (`.key`), certificates (`.crt`), cloud credentials, or generated `kubeconfig` files with real credentials.
- Always provide template configurations (`*.yaml.example`) and ignore generated state via `.gitignore`.
- Destructive actions (such as `reset.sh` or uninstalls) **must display explicit warnings** and require interactive confirmation or an explicit `--force` flag.

### E. Explicit Target Versions
- Avoid unqualified `latest` tags.
- Pin and document tested Kubernetes and component versions (e.g., Kubernetes `v1.31.x` on Ubuntu `22.04` and `24.04` LTS).

---

## 4. Standard Directory Layout for Implementation Branches

Every implementation branch should consistently follow this layout:
```text
<branch-root>/
├── README.md               # Quickstart, visual workflow, topology, and execution summary
├── ARCHITECTURE.md         # Component topology, internal data paths, and network flows
├── PREREQUISITES.md        # Hardware, OS, kernel, port, and network requirements
├── TROUBLESHOOTING.md      # Matrix of known failures, diagnostic commands, and resolutions
├── RESET.md                # Node cleanup, state teardown, and reset instructions
│
├── docs/                   # Deep-dive conceptual guides
│   ├── architecture.md     # Detailed component breakdown
│   ├── networking.md       # CNI, service routing, DNS, and traffic diagrams
│   ├── components.md       # Binary roles, systemd units, configuration files
│   └── validation.md       # Cluster verification criteria & test scenarios
│
├── scripts/                # Numbered, idempotent shell automation scripts
│   ├── 01-prerequisites.sh
│   ├── 02-system-config.sh
│   ├── 03-container-runtime.sh
│   ├── 04-install-kubernetes.sh
│   ├── 05-init-cluster.sh
│   ├── 06-install-cni.sh
│   ├── 07-join-workers.sh
│   └── 08-validate.sh
│
├── configs/                # Sample configuration templates, daemon configs, sysctl, manifests
│
├── examples/               # Verification workloads (e.g. nginx deployment, service, ingress test)
│
└── tests/                  # Automated verification & diagnostic test runners
```

---

## 5. Branch Completion Checklist

An implementation branch is **NOT** complete until every checkbox is verified:
- [ ] Comprehensive `README.md` with step-by-step guidance.
- [ ] `ARCHITECTURE.md` explaining component lifecycle and network topology.
- [ ] `PREREQUISITES.md` documenting hardware, OS, kernel, and firewall ports.
- [ ] `TROUBLESHOOTING.md` containing actionable problem-cause-check-fix entries.
- [ ] `RESET.md` and safe teardown scripts.
- [ ] All numbered scripts in `scripts/` are executable, idempotent, and include error handling.
- [ ] End-to-end validation script in `scripts/08-validate.sh` and manifests in `examples/`.
- [ ] `.gitignore` prevents leaks of keys, certificates, tokens, or local kubeconfigs.
- [ ] Git commit history is clean, descriptive, and pushed to `origin/<branch>`.
