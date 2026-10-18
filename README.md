# MicroK8s Installation Laboratory 📦

> **Canonical Zero-Ops Snap-Packaged Kubernetes**  
> *Target Audience:* Beginners, Linux Operators, Edge & Workstation Developers  
> *Target OS:* Ubuntu 22.04 LTS / 24.04 LTS (any Linux with `snapd`)  
> *Target Distribution Version:* MicroK8s v1.31 / v1.30 (Strict or Classic Confinement)

---

## 🎯 What is MicroK8s?

**MicroK8s** is Canonical's zero-ops, pure upstream Kubernetes distribution delivered through the universal **Snap** packaging system. It is engineered to run seamlessly across developer workstations, IoT devices, edge clusters, and bare-metal servers.

### Key Architectural Pillars:
1. **Snap Packaging:** All binaries, libraries, and configurations are packaged into an immutable snap file. Updates and rollbacks are managed automatically by `snapd`.
2. **Dqlite Datastore:** For high-availability clustering, MicroK8s uses **Dqlite** (*Distributed SQLite*), an ultra-fast, transactional Raft-replicated SQL database.
3. **Instant Addons:** Enable production capabilities without complex Helm charts:
   ```bash
   microk8s enable dns ingress storage metallb
   ```
4. **Isolated Filesystem:** Data and configurations live under `/var/snap/microk8s/current/`, isolating Kubernetes completely from host filesystem collisions.

---

## 🏗️ Laboratory Topology

```
                  Host Network: 10.10.10.0/24 (Example Subnet)
                                      |
         +----------------------------+----------------------------+
         |                                                         |
         v                                                         v
+-------------------------+                               +-------------------------+
|     microk8s-node-01    |                               |     microk8s-node-02    |
| IP: 10.10.10.10         |                               | IP: 10.10.10.11         |
| Role: Initial Node (CP) |                               | Role: Clustered Node    |
| 2 vCPU, 4 GB RAM        |                               | 2 vCPU, 2 GB RAM        |
+-------------------------+                               +-------------------------+
```

---

## 📋 Step-by-Step Installation Workflow

Follow the numbered scripts in `scripts/`:

```bash
# Step 1: Check snapd support, memory, and firewall ports
sudo ./scripts/01-prerequisites.sh

# Step 2: Install MicroK8s snap package and configure user permissions
sudo ./scripts/02-install-snap.sh

# Step 3: Initialize cluster and wait for node readiness
./scripts/03-init-cluster.sh

# Step 4: Enable essential addons (dns, ingress, hostpath-storage)
./scripts/04-enable-addons.sh

# Step 5: (Optional) Generate node join tokens for multi-node clustering
./scripts/05-join-nodes.sh

# Step 6: Validate cluster health and deploy test workload
./scripts/06-validate.sh
```

---

## 🔄 Reset & Cleanup

To wipe the cluster state or completely uninstall the snap:
```bash
sudo ./scripts/reset.sh
```

---

## 📖 Deep Dives

- [ARCHITECTURE.md](file:///home/vivek/k8s-proj/ARCHITECTURE.md) — Snap confinement, Dqlite distributed consensus, and addon engine.
- [PREREQUISITES.md](file:///home/vivek/k8s-proj/PREREQUISITES.md) — System requirements and firewall port matrix.
- [TROUBLESHOOTING.md](file:///home/vivek/k8s-proj/TROUBLESHOOTING.md) — Snap permissions, Dqlite locks, and addon failures.
- [docs/networking.md](file:///home/vivek/k8s-proj/docs/networking.md) — Embedded Calico networking, Ingress, and MetalLB.
