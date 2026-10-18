# RKE2 (Rancher Government) Installation Laboratory 🛡️

> **Next-Generation Security-Hardened Kubernetes (CIS & FIPS Compliant)**  
> *Target Audience:* Intermediate to Senior Platform Engineers & SREs  
> *Target OS:* Ubuntu 22.04 LTS / 24.04 LTS (also RHEL, Rocky Linux)  
> *Target Distribution Version:* RKE2 v1.31.x / v1.30.x

---

## 🎯 What is RKE2?

**RKE2** (also known as *RKE Government*) is Rancher's enterprise distribution engineered from the ground up for mission-critical and defense environments. It merges the deployment simplicity and packaging of K3s with strict upstream Kubernetes alignment and Center for Internet Security (CIS) compliance.

> [!IMPORTANT]
> **RKE2 is NOT RKE1 (RKE Classic).**
> - *RKE1* relied on Docker and automated SSH connections from an external workstation.
> - *RKE2* is fully self-contained, runs as native `systemd` services (`rke2-server` / `rke2-agent`), embeds its own hardened `containerd` runtime, and uses embedded `etcd` for consensus.

### Key Architectural Pillars:
1. **CIS Benchmark Hardening:** Designed to pass CIS Kubernetes Benchmark tests out of the box with zero manual audit remediation.
2. **Embedded etcd Datastore:** Unlike K3s which defaults to SQLite/Kine, RKE2 always runs standard, production-ready `etcd`.
3. **Batteries Included & Hardened:** Ships with embedded containerd, Canal CNI (Calico + Flannel) or Cilium, CoreDNS, NGINX Ingress Controller, and Metrics Server.
4. **FIPS 140-2 Cryptographic Alignment:** Provides built-in support for FIPS-validated cryptography modules.

---

## 🏗️ Laboratory Topology

```
                  Host Network: 10.10.10.0/24 (Example Subnet)
                                      |
         +----------------------------+----------------------------+
         |                                                         |
         v                                                         v
+-------------------------+                               +-------------------------+
|      rke2-server-01     |                               |       rke2-agent-01     |
| IP: 10.10.10.10         |                               | IP: 10.10.10.11         |
| Role: Server (Control)  |                               | Role: Agent (Worker)    |
| 2 vCPU, 4 GB RAM        |                               | 2 vCPU, 2 GB RAM        |
+-------------------------+                               +-------------------------+
```

---

## 📋 Step-by-Step Installation Workflow

Follow the numbered scripts in `scripts/`:

### On RKE2 Server (`rke2-server-01`):
```bash
# Step 1: Validate system resources, kernel, and ports
sudo ./scripts/01-prerequisites.sh

# Step 2: Configure kernel modules, sysctl, and limits
sudo ./scripts/02-system-config.sh

# Step 3: Install RKE2 server and initialize systemd service
sudo ./scripts/03-install-server.sh

# Step 4: Configure user environment and verify kubectl
./scripts/04-configure.sh
```

### On RKE2 Agent Worker Node (`rke2-agent-01`):
```bash
# Run steps 1 and 2 on the agent node:
sudo ./scripts/01-prerequisites.sh
sudo ./scripts/02-system-config.sh

# Step 5: Join the agent node to the server
# (Obtain the node-token from /var/lib/rancher/rke2/server/node-token on the server)
sudo ./scripts/05-join-agents.sh https://10.10.10.10:9345 <NODE_TOKEN>
```

### Post-Installation Cluster Validation:
```bash
# Step 6: Validate nodes, pods, Canal CNI, and run test workload
./scripts/06-validate.sh
```

---

## 🔍 What Happens During RKE2 Installation?

1. **Binary Placement:** Installs `/usr/local/bin/rke2` and runtime utilities into `/var/lib/rancher/rke2/bin/` (`kubectl`, `crictl`, `ctr`).
2. **Systemd Unit Generation:** Generates `rke2-server.service` and `rke2-agent.service`.
3. **Control Plane Spin-Up:** RKE2 launches `etcd`, `kube-apiserver`, `kube-controller-manager`, and `kube-scheduler` as static pods managed by its embedded kubelet.
4. **Registration Port (`9345`):** RKE2 opens TCP port `9345` (*Supervisor API*) exclusively for node join handshakes and token verification, keeping the Kubernetes API on `6443` strictly separated.
5. **HelmChart Controller:** Automatically deploys bundled HelmCharts: Canal CNI, CoreDNS, NGINX Ingress Controller, and Metrics Server.

---

## 🔄 Reset & Cleanup

To uninstall RKE2 cleanly:
```bash
sudo ./scripts/reset.sh
```
Or use the official uninstaller:
```bash
sudo /usr/local/bin/rke2-uninstall.sh        # on server
sudo /usr/local/bin/rke2-agent-uninstall.sh  # on agent
```

---

## 📖 Deep Dives

- [ARCHITECTURE.md](file:///home/vivek/k8s-proj/ARCHITECTURE.md) — RKE2 internal mechanics, Supervisor API (9345), and CIS hardening.
- [PREREQUISITES.md](file:///home/vivek/k8s-proj/PREREQUISITES.md) — Hardware specs and firewall port matrix.
- [TROUBLESHOOTING.md](file:///home/vivek/k8s-proj/TROUBLESHOOTING.md) — Common RKE2 failures and remediation.
- [docs/networking.md](file:///home/vivek/k8s-proj/docs/networking.md) — Canal CNI and NGINX Ingress routing.
