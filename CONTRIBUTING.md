# Contributing to kube-forge

Thank you for your interest in contributing to **kube-forge: The Kubernetes Installation Laboratory and Framework**!

`kube-forge` is committed to maintaining high pedagogical clarity, strict technical precision, and zero-compromise security standards.

---

## 1. Guiding Principles

1. **Pedagogy First:** Every line of code or configuration must be understandable. Avoid opaque one-liners or unnecessary automation abstractions.
2. **Explain the Why:** Never just say "run this command". Explain what binary executes, which kernel feature is invoked, what port opens, and why Kubernetes requires it.
3. **Strict Branch Isolation:** Every installation paradigm lives on its own branch. Do not submit PRs mixing different installation technologies into a single branch.
4. **Idempotence & Safety:** Scripts should safely inspect current system state before mutating files or kernel settings. Backups of system files (`/etc/sysctl.conf`, etc.) must be taken.
5. **No Committed Secrets:** Pull requests containing private keys, live certificates, plaintext tokens, or real kubeconfigs will be immediately rejected.

---

## 2. Repository Branches

All work must be targeted to the appropriate branch:
- `main` — Project documentation, architectural blueprints, comparison matrices, and agent skills.
- `kubeadm` — Standard upstream bootstrap implementation.
- `k3s` — Lightweight packaged Kubernetes implementation.
- `rke2` — Security-hardened enterprise Rancher distribution.
- `hardway` — Manual step-by-step from-scratch installation.
- `minikube` — Local development & learning sandbox.
- `microk8s` — Canonical zero-ops snap distribution.
- `kubespray` — Ansible-driven multi-node production deployment.
- `talos` — Immutable Linux appliance OS installation.

---

## 3. Standard Branch Structure

When enhancing or introducing a branch, follow this structure:

```text
├── README.md               # Quickstart, visual workflow, topology, and execution summary
├── ARCHITECTURE.md         # Component topology, internal data paths, and network flows
├── PREREQUISITES.md        # Hardware, OS, kernel, port, and network requirements
├── TROUBLESHOOTING.md      # Matrix of known failures, diagnostic commands, and resolutions
├── RESET.md                # Node cleanup, state teardown, and reset instructions
├── docs/                   # Deep-dive conceptual guides
│   ├── architecture.md
│   ├── networking.md
│   ├── components.md
│   └── validation.md
├── scripts/                # Numbered shell scripts (01-prerequisites.sh .. 08-validate.sh)
├── configs/                # Configuration templates (*.yaml.example, *.toml)
├── examples/               # Test workloads (nginx, services, ingress)
└── tests/                  # Verification and automated diagnostic scripts
```

---

## 4. Shell Script Standards

All scripts in `scripts/` must:
- Include `set -euo pipefail` at the top.
- Provide descriptive logging with prefixes like `[INFO]`, `[SUCCESS]`, `[WARN]`, `[ERROR]`.
- Check for `root` or `sudo` privileges where required:
  ```bash
  if [[ $EUID -ne 0 ]]; then
      echo "[ERROR] This script must be run as root or with sudo." >&2
      exit 1
  fi
  ```
- Check for existing prerequisites before attempting re-installation.
- For reset/cleanup scripts: **always prompt for user confirmation** unless an explicit `--force` or `-y` flag is passed.

---

## 5. Commit & Pull Request Guidelines

Use clear, standardized commit messages:
```bash
feat: add containerd installation script for kubeadm
docs: add network flow diagram to rke2 architecture
fix: correct sysctl ip_forward verification in prerequisites
test: add pod-to-pod cross-node ping validation
```

Ensure your branch has no leftover generated credentials, test tokens, or trailing whitespace before submitting a Pull Request.
