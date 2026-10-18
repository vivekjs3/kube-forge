# Kubeadm Architecture & Internal Mechanics

This document provides a technical deep dive into how `kubeadm` establishes, configures, and manages a Kubernetes cluster on Linux.

---

## 1. High-Level Static Pod Architecture

Unlike manual installations where control plane components run as standalone systemd units, `kubeadm` employs the **Static Pod** pattern:

```
+-------------------------------------------------------------------------------+
|                            CONTROL PLANE HOST (Linux)                         |
|                                                                               |
|  +-------------------------------------------------------------------------+  |
|  |                     systemd (Linux Init System)                         |  |
|  |                                                                         |  |
|  |     +-------------------------+         +-------------------------+     |  |
|  |     |   containerd.service    |         |     kubelet.service     |     |  |
|  |     |   (CRI Runtime Daemon)  |         |   (Host Node Agent)     |     |  |
|  |     +------------+------------+         +------------+------------+     |  |
|  +------------------|-----------------------------------|------------------+  |
|                     | (gRPC CRI Unix Socket)            |                     |
|                     +-----------------------------------+                     |
|                                                                               |
|  +-------------------------------------------------------------------------+  |
|  |             Static Pod Manifests: /etc/kubernetes/manifests/            |  |
|  |   - kube-apiserver.yaml          - kube-controller-manager.yaml         |  |
|  |   - etcd.yaml                    - kube-scheduler.yaml                  |  |
|  +-------------------------------------------------------------------------+  |
|                                          |                                    |
|                                          v (Kubelet watches filesystem)       |
|  +-------------------------------------------------------------------------+  |
|  |                       CONTAINERIZED CONTROL PLANE                       |  |
|  |                                                                         |  |
|  |   +-----------------------+                    +--------------------+   |  |
|  |   |     kube-apiserver    | <----------------> |    etcd container  |   |  |
|  |   |   (HostPort: 6443)    |                    | (127.0.0.1:2379)   |   |  |
|  |   +-----------+-----------+                    +--------------------+   |  |
|  |               ^                                                         |  |
|  |               | (mTLS Local Loopback)                                   |  |
|  |       +-------+-------+                                                 |  |
|  |       |               |                                                 |  |
|  |   +---+---------------+---+                    +--------------------+   |  |
|  |   |    kube-scheduler     |                    | kube-controller-mgr|   |  |
|  |   +-----------------------+                    +--------------------+   |  |
|  +-------------------------------------------------------------------------+  |
+-------------------------------------------------------------------------------+
```

### Why Static Pods?
- **Self-Healing:** If `kube-apiserver` crashes, the local `kubelet` automatically restarts its container without needing external daemon managers.
- **Upgradability:** To upgrade the control plane, `kubeadm upgrade` simply writes updated image tags to the manifests in `/etc/kubernetes/manifests/`. Kubelet detects the change and replaces the containers gracefully.
- **Portability:** Control plane binaries are packaged as standardized OCI container images from `registry.k8s.io`.

---

## 2. Directory & State Layout

| Directory / File Path | Ownership | Purpose & Contents |
|---|---|---|
| `/etc/kubernetes/admin.conf` | `root:root` (0600) | Full cluster administrator kubeconfig containing embedded client X.509 certs. |
| `/etc/kubernetes/kubelet.conf` | `root:root` (0600) | Kubelet identity kubeconfig used to report node health. |
| `/etc/kubernetes/manifests/` | `root:root` (0700) | Static Pod definitions watched continuously by kubelet. |
| `/etc/kubernetes/pki/` | `root:root` (0700) | Cluster CA (`ca.crt`, `ca.key`), API server certs, front-proxy certs. |
| `/etc/kubernetes/pki/etcd/` | `root:root` (0700) | Dedicated etcd CA and peer/server certificates. |
| `/var/lib/etcd/` | `root:root` (0700) | Persistent Write-Ahead Log (WAL) and snapshot database for etcd. |
| `/var/lib/kubelet/` | `root:root` (0750) | Kubelet state, volume mounts, plugin registrations, pod volumes. |
| `/etc/containerd/config.toml` | `root:root` (0644) | Container runtime configuration (systemd cgroup driver). |

---

## 3. Worker Node Join Mechanics (TLS Bootstrapping)

When `kubeadm join` executes on a worker node:

```
Worker Node                                               Control Plane Node
    |                                                             |
    | 1. Connect to https://10.10.10.10:6443                      |
    |    Validate cluster CA hash (--discovery-token-ca-cert-hash)|
    |------------------------------------------------------------>|
    |                                                             |
    | 2. Authenticate with temporary Bootstrap Token              |
    |------------------------------------------------------------>|
    |                                                             |
    | 3. Submit Certificate Signing Request (CSR) for Kubelet     |
    |------------------------------------------------------------>|
    |                                                             |
    | 4. Controller Manager verifies token & auto-approves CSR    |
    |                                                             |
    | 5. Issue client X.509 certificate (kubelet.conf)            |
    |<------------------------------------------------------------|
    |                                                             |
    | 6. Kubelet starts & registers node object with API server   |
    |------------------------------------------------------------>|
```

---

## 4. Why CNI Must Be Installed Post-Init

Immediately after `kubeadm init` completes:
- The control plane node reports status **`NotReady`**.
- CoreDNS pods remain in **`Pending`** status.

**Why?**
Kubernetes does not bundle a default network routing engine. Kubelet inspects `/etc/cni/net.d/` for a valid CNI configuration. Until a CNI plugin (e.g. Calico or Flannel) writes this configuration file:
1. Kubelet flags `NetworkPluginNotReady`.
2. CoreDNS has no IP allocator and cannot be scheduled.
3. Once the CNI DaemonSet deploys, all nodes transition to **`Ready`** and CoreDNS pods spin up into **`Running`**.
