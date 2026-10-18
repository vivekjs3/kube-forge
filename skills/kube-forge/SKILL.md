---
name: kube-forge
description: Guide and operational cheatsheet for navigating, deploying, validating, and troubleshooting Kubernetes clusters across all kube-forge installation branches.
---

# Kube-Forge Platform Skill

Use this skill to guide users through selecting, deploying, testing, and troubleshooting Kubernetes clusters across the `kube-forge` repository branches.

---

## 1. Branch Navigation & Selection

`kube-forge` isolates each Kubernetes deployment methodology onto its own branch to keep scripts clean and focused.

```bash
# View available installation branches
git branch -a

# Switch to a target installation branch
git checkout <branch-name>
```

### Branch Quick-Reference:
- **`kubeadm`**: Upstream CNCF standard, containerd, modular CNI (Calico/Flannel), static pods.
- **`k3s`**: Lightweight single binary, embedded SQLite/etcd, low memory footprint.
- **`rke2`**: Rancher Government, FIPS/CIS hardened, embedded containerd & Canal/Cilium.
- **`hardway`**: Step-by-step from-scratch binary installation, manual PKI, systemd units.
- **`minikube`**: Local workstation sandbox, container/VM drivers, built-in addons.
- **`microk8s`**: Canonical Snap-based single/multi-node distribution, zero-ops addons.
- **`kubespray`**: Production-grade Ansible automation for multi-node bare-metal deployments.
- **`talos`**: Immutable API-driven Linux appliance OS with declarative YAML configs.

---

## 2. Standard Laboratory Execution Workflow

When operating inside any implementation branch, follow the numbered sequence in `scripts/`:

```bash
# Step 1: Verify host hardware, OS kernel, and ports
sudo ./scripts/01-prerequisites.sh

# Step 2: Configure kernel modules, sysctl, and disable swap
sudo ./scripts/02-system-config.sh

# Step 3: Install container runtime (containerd/CRI) or distro binary
sudo ./scripts/03-container-runtime.sh

# Step 4: Install Kubernetes packages / binaries
sudo ./scripts/04-install-kubernetes.sh

# Step 5: Initialize cluster control plane
sudo ./scripts/05-init-cluster.sh

# Step 6: Install CNI network plugin
./scripts/06-install-cni.sh

# Step 7: On worker nodes, execute worker join script
sudo ./scripts/07-join-workers.sh

# Step 8: Execute end-to-end cluster validation
./scripts/08-validate.sh
```

---

## 3. Standard Verification Checklist

When validating any cluster deployment, ensure:
1. **Node Status:** All nodes report `Ready` (`kubectl get nodes -o wide`).
2. **Control Plane Pods:** All control plane components in `kube-system` are `Running` and healthy (`kubectl get pods -n kube-system`).
3. **CoreDNS:** CoreDNS pods are `Running` and have non-host Pod IPs.
4. **CNI Agents:** DaemonSets for the CNI are running on all nodes (`kubectl get daemonset -n kube-system`).
5. **Workload Deployment:** Deploy a test nginx deployment, expose as a Service, and verify pod-to-pod and service DNS resolution.

---

## 4. Reset & Cleanup Protocol

Always run the branch's cleanup script before switching branches or tearing down test nodes:
```bash
sudo ./scripts/reset.sh
```
Ensure you have backed up any critical persistent data before running destructive teardowns.
