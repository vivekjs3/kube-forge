# RKE2 Architecture & Internal Mechanics

This document provides a technical deep dive into **RKE2 (RKE Government)** architecture, security hardening, and process supervision.

---

## 1. High-Level System Architecture

RKE2 combines the packaging model of K3s with standard upstream Kubernetes control-plane components and rigorous CIS benchmark compliance.

```
+---------------------------------------------------------------------------------------+
|                                    RKE2 SERVER NODE                                   |
|                                                                                       |
|   +-------------------------------------------------------------------------------+   |
|   |                      systemd: rke2-server.service                             |   |
|   |                                                                               |   |
|   |   +-----------------------------------------------------------------------+   |   |
|   |   |                   RKE2 Supervisor Process                             |   |   |
|   |   |   - Node Registration & Token Validation (TCP Port 9345)              |   |   |
|   |   |   - Internal PKI Certificate Authority Manager                        |   |   |
|   |   |   - HelmChart Controller (Canal, NGINX Ingress, CoreDNS)              |   |   |
|   |   +-----------------------------------------------------------------------+   |   |
|   |                                                                               |   |
|   |   +-----------------------------------------------------------------------+   |   |
|   |   |                    Containerized Control Plane                        |   |   |
|   |   |   - kube-apiserver (Port 6443)                                        |   |   |
|   |   |   - etcd (Port 2379/2380)                                             |   |   |
|   |   |   - kube-controller-manager                                           |   |   |
|   |   |   - kube-scheduler                                                    |   |   |
|   |   +-----------------------------------------------------------------------+   |   |
|   |                                                                               |   |
|   |   +-----------------------------------------------------------------------+   |   |
|   |   |                    Embedded Node Agent Components                     |   |   |
|   |   |   - Embedded kubelet                                                  |   |   |
|   |   |   - Embedded containerd (/run/k3s/containerd/containerd.sock)         |   |   |
|   |   |   - Canal CNI (Calico for Policy + Flannel for VXLAN encapsulation)   |   |   |
|   |   |   - kube-proxy                                                        |   |   |
|   |   +-----------------------------------------------------------------------+   |   |
|   +-------------------------------------------------------------------------------+   |
+---------------------------------------------------------------------------------------+
                                          |
                                          | HTTPS 9345 (Supervisor / Join Token)
                                          | HTTPS 6443 (Kubernetes API Server)
                                          v
+---------------------------------------------------------------------------------------+
|                                     RKE2 AGENT NODE                                   |
|                                                                                       |
|   +-------------------------------------------------------------------------------+   |
|   |                       systemd: rke2-agent.service                             |   |
|   |   - Embedded kubelet (CIS Hardened flags)                                     |   |
|   |   - Embedded containerd runtime                                               |   |
|   |   - Canal CNI agent pod                                                       |   |
|   |   - kube-proxy                                                                |   |
|   +-------------------------------------------------------------------------------+   |
+---------------------------------------------------------------------------------------+
```

---

## 2. Port 9345 vs. Port 6443 (Supervisor Separation)

A critical innovation in RKE2 is the architectural decoupling of node supervision from the Kubernetes API:
- **Port `6443` (Kubernetes API):** Dedicated strictly to standard Kubernetes REST traffic from `kubectl`, controllers, and workloads.
- **Port `9345` (Supervisor API):** A lightweight HTTPS gateway used exclusively by new nodes joining the cluster to negotiate TLS certificates, exchange tokens, and receive cluster configuration.

---

## 3. CIS Benchmark Hardening Profile

When running in CIS mode (e.g., `profile: "cis-1.23"` in `/etc/rancher/rke2/config.yaml`), RKE2 enforces:
1. **Kernel Parameters:** Automatically verifies sysctl settings (e.g. `vm.panic_on_oom=0`, `kernel.panic=10`, `kernel.keys.root_maxkeys=1000000`).
2. **File Permissions:** Enforces strict `0600` permissions on all control-plane static pod manifests and PKI certificates.
3. **Kubelet Hardening:** Disables `--anonymous-auth`, enables `--protect-kernel-defaults=true`, and enforces read-only port disabling (`--read-only-port=0`).

---

## 4. Key File & Directory Layout

| Path | Purpose |
|---|---|
| `/usr/local/bin/rke2` | Main installer and CLI binary |
| `/var/lib/rancher/rke2/bin/` | Packaged binaries: `kubectl`, `crictl`, `ctr` |
| `/etc/rancher/rke2/config.yaml` | Declarative RKE2 configuration file |
| `/etc/rancher/rke2/rke2.yaml` | Cluster administrator kubeconfig |
| `/var/lib/rancher/rke2/server/node-token` | Secret bootstrap join token |
| `/var/lib/rancher/rke2/server/manifests/` | Auto-deploy HelmChart manifests |
| `/var/lib/rancher/rke2/server/tls/` | PKI certificates and CAs |
