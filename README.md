# Kubespray Bare-Metal Automation Laboratory 📜

> **Production Ansible-Driven Kubernetes Fleet Automation**  
> *Target Audience:* DevOps Engineers, SREs, and Bare-Metal Infrastructure Architects  
> *Target OS:* Ubuntu 22.04 / 24.04 LTS, Debian, Rocky Linux, RHEL, AlmaLinux  
> *Technology Stack:* Ansible, Python Virtualenv, Upstream Kubernetes

---

## ⚠️ Important Architectural Context

> [!NOTE]
> **Kubespray is NOT a Kubernetes distribution.**
> Kubespray is an **Infrastructure as Code (IaC) automation framework** powered by **Ansible**. It provisions standard, CNCF-certified upstream Kubernetes clusters across heterogeneous Linux server fleets.

---

## 🎯 What is Kubespray?

Maintained under the CNCF Kubernetes SIGs umbrella, Kubespray provides battle-tested Ansible playbooks for day-1 deployments and day-2 lifecycle management (cluster scaling, node draining, automated rolling OS and Kubernetes version upgrades).

### Key Architectural Strengths:
1. **Multi-OS Heterogeneous Fleets:** Seamlessly deploys across Ubuntu, Debian, Rocky Linux, RHEL, AlmaLinux, Flatcar, and openSUSE.
2. **Declarative Inventory:** Infrastructure topology is declared in human-readable YAML/INI inventories defining `kube_control_plane`, `kube_node`, and `etcd` node groups.
3. **Pluggable CNI:** Out-of-the-box support for Calico, Cilium, Flannel, Kube-ovn, and Kube-router via simple configuration variables.
4. **Day-2 Operations:** Includes specialized playbooks:
   - `cluster.yml`: Full cluster provisioning.
   - `scale.yml`: Adding new worker nodes without touching running control planes.
   - `upgrade-cluster.yml`: Zero-downtime rolling upgrades.
   - `reset.yml`: Clean cluster teardown.

---

## 🏗️ Laboratory Topology

```
                  Ansible Controller Host (Workstation / CI Runner)
                                        |
                 (SSH Key-Based Authentication / Port 22)
                                        |
         ===============================+===============================
                          Target Node Subnet (10.10.10.0/24)
                                        |
         +------------------------------+------------------------------+
         |                                                             |
         v                                                             v
+-------------------------+                                   +-------------------------+
|     k8s-control-01      |                                   |      k8s-worker-01      |
| IP: 10.10.10.10         |                                   | IP: 10.10.10.11         |
| Groups:                 |                                   | Groups:                 |
| - kube_control_plane    |                                   | - kube_node             |
| - etcd                  |                                   | 2 vCPU, 2 GB RAM        |
| 2 vCPU, 4 GB RAM        |                                   +-------------------------+
+-------------------------+                                                |
                                                                           v
                                                              +-------------------------+
                                                              |      k8s-worker-02      |
                                                              | IP: 10.10.10.12         |
                                                              | Groups:                 |
                                                              | - kube_node             |
                                                              | 2 vCPU, 2 GB RAM        |
                                                              +-------------------------+
```

---

## 📋 Step-by-Step Installation Workflow

Follow the numbered scripts in `scripts/`:

```bash
# Step 1: Install Python3, venv, and Ansible dependencies on the controller host
./scripts/01-prerequisites.sh

# Step 2: Clone Kubespray repo and generate customized inventory.ini
./scripts/02-setup-inventory.sh

# Step 3: Execute cluster deployment playbook (cluster.yml)
./scripts/03-deploy-cluster.sh

# Step 4: (Optional) Scale the cluster by adding a worker node (scale.yml)
./scripts/04-scale-worker.sh <WORKER_NODE_NAME>

# Step 5: Validate cluster health and deploy test workload
./scripts/05-validate.sh
```

---

## 🔄 Reset & Cleanup

To cleanly wipe all nodes using Kubespray's automated `reset.yml` playbook:
```bash
./scripts/reset.sh
```

---

## 📖 Deep Dives

- [ARCHITECTURE.md](file:///home/vivek/k8s-proj/ARCHITECTURE.md) — Ansible playbooks, role hierarchies, and node group semantics.
- [PREREQUISITES.md](file:///home/vivek/k8s-proj/PREREQUISITES.md) — Controller host, SSH keys, and target machine requirements.
- [TROUBLESHOOTING.md](file:///home/vivek/k8s-proj/TROUBLESHOOTING.md) — Common Ansible failures, SSH timeouts, and pip issues.
- [docs/networking.md](file:///home/vivek/k8s-proj/docs/networking.md) — Selecting and tuning CNI plugins in Kubespray.
