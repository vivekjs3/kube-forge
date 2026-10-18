# Minikube Installation Laboratory 💻

> **Local Developer & Learning Sandbox**  
> *Target Audience:* Beginners, Application Developers, and Testers  
> *Target OS:* Ubuntu 22.04 LTS / 24.04 LTS (macOS / Windows also supported)  
> *Primary Drivers:* Docker (containerized) or KVM2 / QEMU (virtualized)

---

## ⚠️ Important Architectural Context

> [!NOTE]
> **Minikube is designed exclusively as a local Kubernetes learning and development environment.**
> It is **NOT** a production bare-metal distribution. It simulates single or multi-node clusters inside a local Docker container or lightweight virtual machine on your developer laptop or workstation.

---

## 🎯 What is Minikube?

Maintained directly by Kubernetes SIG Cluster Lifecycle, Minikube provides a fast, one-command path to spin up an ephemeral, CNCF-certified Kubernetes cluster locally.

### Key Capabilities:
1. **Multiple Drivers:** Runs directly inside a local Docker container (fastest, lowest overhead) or inside a true hypervisor VM (KVM2, QEMU, VirtualBox).
2. **Instant Addons:** Enable production capabilities with a single command:
   ```bash
   minikube addons enable ingress
   minikube addons enable metrics-server
   minikube addons enable dashboard
   ```
3. **Network Tunneling (`minikube tunnel`):** Bridges virtual cluster IP spaces directly to your developer workstation host route table, allowing direct access to `type: LoadBalancer` services.
4. **Multi-Node Simulation:** Allows running simulated multi-node clusters on a single machine:
   ```bash
   minikube start --nodes 3
   ```

---

## 🏗️ Laboratory Architecture

```
+-------------------------------------------------------------------------------+
|                       DEVELOPER WORKSTATION / LAPTOP                          |
|                                                                               |
|   +-----------------------------------------------------------------------+   |
|   |                        minikube CLI (/usr/local/bin)                  |   |
|   +-----------------------------------+-----------------------------------+   |
|                                       |                                       |
|                  +--------------------+--------------------+                  |
|                  | (Driver Choice)                         |                  |
|                  v                                         v                  |
|   +-------------------------------+         +-----------------------------+   |
|   |      Docker Driver (Default)  |         |     KVM2 / QEMU Driver      |   |
|   |   Runs complete K8s node in   |   OR    |   Runs complete K8s node in |   |
|   |   an isolated Docker container|         |   a dedicated Linux KVM VM  |   |
|   +---------------+---------------+         +--------------+--------------+   |
|                   |                                        |                  |
|                   +-------------------+--------------------+                  |
|                                       |                                       |
|                                       v                                       |
|   +-----------------------------------------------------------------------+   |
|   |                     MINIKUBE CLUSTER SANDBOX                          |   |
|   |   - Control Plane (kube-apiserver, etcd, scheduler, controller-mgr)   |   |
|   |   - Worker Engine (kubelet, containerd CRI, CNI)                      |   |
|   |   - Bundled Addons (Ingress Controller, Metrics Server, StorageClass) |   |
|   +-----------------------------------------------------------------------+   |
+-------------------------------------------------------------------------------+
```

---

## 📋 Step-by-Step Installation Workflow

Follow the numbered scripts in `scripts/`:

```bash
# Step 1: Check virtualization flags, RAM, and Docker engine
sudo ./scripts/01-prerequisites.sh

# Step 2: Download and install the minikube & kubectl binaries
sudo ./scripts/02-install-minikube.sh

# Step 3: Create the local Kubernetes cluster
./scripts/03-create-cluster.sh

# Step 4: Enable essential addons (ingress, metrics-server)
./scripts/04-enable-addons.sh

# Step 5: Validate cluster health and deploy a test workload
./scripts/05-validate.sh
```

---

## 🔄 Reset & Cleanup

To stop and permanently delete the Minikube cluster sandbox:
```bash
./scripts/reset.sh
```

---

## 📖 Deep Dives

- [ARCHITECTURE.md](file:///home/vivek/k8s-proj/ARCHITECTURE.md) — Drivers, virtualization encapsulation, and addon controller.
- [PREREQUISITES.md](file:///home/vivek/k8s-proj/PREREQUISITES.md) — Docker and hardware virtualization requirements.
- [TROUBLESHOOTING.md](file:///home/vivek/k8s-proj/TROUBLESHOOTING.md) — Driver crashes, permission issues, and tunnel timeouts.
- [docs/networking.md](file:///home/vivek/k8s-proj/docs/networking.md) — `minikube tunnel`, `minikube service`, and port-forwarding.
