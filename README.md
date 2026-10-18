# K3s Installation Laboratory ⚡

> **Lightweight, Packaged Kubernetes for Edge, IoT, and Minimal Footprint Infrastructure**  
> *Target Audience:* Beginners to Intermediate Platform Engineers  
> *Target OS:* Ubuntu 22.04 LTS / 24.04 LTS (also Debian, Alpine, Raspberry Pi OS)  
> *Target Distribution Version:* K3s v1.31.x / v1.30.x

---

## 🎯 What is K3s?

**K3s** is a certified, fully compliant Kubernetes distribution created by Rancher / SUSE and donated to the CNCF as a Sandbox project. It is engineered specifically for resource-constrained environments: edge devices, IoT gateways, branch offices, local development workstations, and automated CI pipelines.

### How K3s Simplifies Kubernetes:
1. **Single Binary Packaging:** All control-plane components (`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`), node agents (`kubelet`, `kube-proxy`), container runtime (`containerd`), and CNI (`Flannel`) are compiled into a single executable binary (`k3s`).
2. **Kine (Datastore Abstraction):** Replaces resource-intensive `etcd` on single-node setups with an embedded SQLite database using **Kine** (an etcd-to-SQL translation shim). HA mode supports embedded etcd or external MySQL/PostgreSQL.
3. **Batteries-Included Architecture:** Bundles out-of-the-box local path storage (`local-path-provisioner`), service load balancing (`ServiceLB` / `klipper-lb`), internal DNS (`CoreDNS`), and ingress controller (`Traefik`).
4. **Minimal Footprint:** Idles with less than **512 MB of RAM** and requires less than 100 MB of disk space.

---

## 🏗️ Laboratory Topology

```
                  Host Network: 10.10.10.0/24 (Example Subnet)
                                      |
         +----------------------------+----------------------------+
         |                                                         |
         v                                                         v
+-------------------------+                               +-------------------------+
|       k3s-server-01     |                               |       k3s-agent-01      |
| IP: 10.10.10.10         |                               | IP: 10.10.10.11         |
| Role: Server (Control)  |                               | Role: Agent (Worker)    |
| 1-2 vCPU, 1 GB RAM      |                               | 1 vCPU, 512 MB RAM      |
+-------------------------+                               +-------------------------+
```

---

## 📋 Step-by-Step Installation Workflow

Follow the numbered scripts in `scripts/`:

### On K3s Server (`k3s-server-01`):
```bash
# Step 1: Check hardware, memory, and kernel prerequisites
sudo ./scripts/01-prerequisites.sh

# Step 2: Configure Linux kernel modules and sysctl forwarding
sudo ./scripts/02-system-config.sh

# Step 3: Install K3s server with declarative config
sudo ./scripts/03-install-server.sh

# Step 4: Configure kubectl access and permissions for current user
./scripts/04-configure.sh
```

### On K3s Agent Worker Node (`k3s-agent-01`):
```bash
# Run steps 1 and 2 on the agent node:
sudo ./scripts/01-prerequisites.sh
sudo ./scripts/02-system-config.sh

# Step 5: Join the agent node to the server
# (Obtain the node-token from /var/lib/rancher/k3s/server/node-token on the server)
sudo ./scripts/05-join-agents.sh https://10.10.10.10:6443 <NODE_TOKEN>
```

### Post-Installation Cluster Validation:
```bash
# Step 6: Validate nodes, pods, Traefik ingress, and deploy test workload
./scripts/06-validate.sh
```

---

## 🔍 What Happens During K3s Installation?

1. **Binary Drop:** The official installer downloads the single `k3s` binary into `/usr/local/bin/k3s`.
2. **Systemd Service Setup:** Creates and enables the `k3s.service` (for server) or `k3s-agent.service` (for worker).
3. **Datastore Init:** Spawns Kine and initializes the embedded SQLite database at `/var/lib/rancher/k3s/server/db/state.db`.
4. **mTLS & Certs:** Generates internal CA and certificates in `/var/lib/rancher/k3s/server/tls/`.
5. **Kubeconfig:** Writes cluster credentials to `/etc/rancher/k3s/k3s.yaml` with mode `0600`.
6. **Embedded Addons:** Deploys CoreDNS, Flannel CNI, Traefik ingress controller, Local Path Provisioner, and ServiceLB.

---

## 🔄 Reset & Cleanup

To completely remove K3s and wipe all cluster state:
```bash
sudo ./scripts/reset.sh
```
Or execute K3s's built-in uninstall script:
```bash
sudo /usr/local/bin/k3s-uninstall.sh        # on server
sudo /usr/local/bin/k3s-agent-uninstall.sh  # on agent
```

---

## 📖 Deep Dives

- [ARCHITECTURE.md](file:///home/vivek/k8s-proj/ARCHITECTURE.md) — K3s single binary architecture, Kine datastore, and data paths.
- [PREREQUISITES.md](file:///home/vivek/k8s-proj/PREREQUISITES.md) — Resource requirements and firewall port matrix.
- [TROUBLESHOOTING.md](file:///home/vivek/k8s-proj/TROUBLESHOOTING.md) — Common K3s issues (token errors, Traefik port conflicts, SQLite locks).
- [docs/networking.md](file:///home/vivek/k8s-proj/docs/networking.md) — Flannel backend options, ServiceLB, and Traefik ingress.
