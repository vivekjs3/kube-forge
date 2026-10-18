# K3s Architecture & Internal Mechanics

This document provides a technical deep dive into the architecture, component packaging, and datastore model of **K3s**.

---

## 1. Single Binary Packaging & Execution Model

In upstream Kubernetes, each component (`apiserver`, `controller-manager`, `scheduler`, `kubelet`, `kube-proxy`, `containerd`, `flannel`) is a distinct process or container. K3s bundles all of these into a single Go binary compiled with multi-call capabilities.

```
+---------------------------------------------------------------------------------------+
|                                    K3S SERVER NODE                                    |
|                                                                                       |
|   +-------------------------------------------------------------------------------+   |
|   |                          k3s server (Single Process)                          |   |
|   |                                                                               |   |
|   |   +-------------------+    +--------------------+    +--------------------+   |   |
|   |   |   kube-scheduler  |    | kube-controller-mgr|    |    CoreDNS / CNI   |   |   |
|   |   +---------+---------+    +----------+---------+    +----------+---------+   |   |
|   |             |                         |                         |             |   |
|   |             v                         v                         v             |   |
|   |      +-------------------------------------------------------------+          |   |
|   |      |               Embedded kube-apiserver (Port 6443)           |          |   |
|   |      +------------------------------+------------------------------+          |   |
|   |                                     | (gRPC)                                  |   |
|   |                                     v                                         |   |
|   |      +-------------------------------------------------------------+          |   |
|   |      |                  Kine (etcd API translation)                |          |   |
|   |      +------------------------------+------------------------------+          |   |
|   |                                     | (SQL Driver)                            |   |
|   |                                     v                                         |   |
|   |      +-------------------------------------------------------------+          |   |
|   |      |              Embedded SQLite (/var/lib/rancher/k3s/...)     |          |   |
|   |      |         (Or embedded etcd / external PostgreSQL/MySQL)      |          |   |
|   |      +-------------------------------------------------------------+          |   |
|   |                                                                               |   |
|   |   +-----------------------------------------------------------------------+   |   |
|   |   |                      Embedded Agent / Worker Loop                     |   |   |
|   |   |   - Embedded kubelet                                                  |   |   |
|   |   |   - Embedded containerd                                               |   |   |
|   |   |   - Embedded Flannel CNI                                              |   |   |
|   |   |   - Embedded kube-proxy (iptables)                                    |   |   |
|   |   +-----------------------------------------------------------------------+   |   |
|   +-------------------------------------------------------------------------------+   |
+---------------------------------------------------------------------------------------+
                                          |
                                          | HTTPS / mTLS (Port 6443)
                                          | Node Registration Token
                                          v
+---------------------------------------------------------------------------------------+
|                                     K3S AGENT NODE                                    |
|                                                                                       |
|   +-------------------------------------------------------------------------------+   |
|   |                           k3s agent (Single Process)                          |   |
|   |   - Embedded kubelet                                                          |   |
|   |   - Embedded containerd (/run/k3s/containerd/containerd.sock)                 |   |
|   |   - Embedded Flannel CNI                                                      |   |
|   |   - Embedded kube-proxy                                                       |   |
|   +-------------------------------------------------------------------------------+   |
+---------------------------------------------------------------------------------------+
```

---

## 2. The Kine Datastore Architecture

One of the largest consumers of memory and CPU in standard Kubernetes is `etcd`. For edge or single-node clusters, K3s replaces etcd with **Kine** (*Kine Is Not Etcd*):

- **How it works:** Kine exposes an `etcd v3` gRPC endpoint to `kube-apiserver`.
- When the API server performs `Get`, `Put`, `Watch`, or `Txn` calls, Kine translates them on the fly into standard SQL queries against a lightweight database engine.
- **Default Database:** Embedded **SQLite** stored locally at `/var/lib/rancher/k3s/server/db/state.db`.
- **HA Modes:**
  - Embedded **etcd** (using `--cluster-init`).
  - External **PostgreSQL** or **MySQL** (using `--datastore-endpoint="postgres://..."`).

---

## 3. Packaged Addons & Controllers

K3s installs essential cluster controllers out of the box so that a freshly booted cluster can immediately serve HTTP traffic and persist volumes:

1. **Flannel CNI:** Configured with VXLAN overlay encapsulation by default.
2. **CoreDNS:** Scaled down and optimized for low memory footprint.
3. **Traefik Ingress Controller:** Automatically deployed via HelmChart controller, binding to host ports 80 and 443.
4. **ServiceLB (klipper-lb):** A lightweight load balancer that allocates host ports on nodes to satisfy `LoadBalancer` type Services without requiring an external cloud provider.
5. **Local-Path Provisioner:** Dynamic storage provisioner creating `hostPath` backed PersistentVolumes in `/var/lib/rancher/k3s/storage/`.

---

## 4. Key File & Directory Layout

| Path | Purpose |
|---|---|
| `/usr/local/bin/k3s` | Universal binary (symlinked to `kubectl`, `crictl`, `ctr`) |
| `/etc/rancher/k3s/config.yaml` | Declarative server/agent configuration file |
| `/etc/rancher/k3s/k3s.yaml` | Administrative kubeconfig |
| `/var/lib/rancher/k3s/server/node-token` | Secret bootstrap token required for agent joining |
| `/var/lib/rancher/k3s/server/tls/` | CA and mTLS certificates generated during bootstrap |
| `/var/lib/rancher/k3s/server/db/` | Embedded SQLite database file (`state.db`) |
| `/var/lib/rancher/k3s/agent/containerd/` | Embedded containerd runtime socket and state |
| `/var/lib/rancher/k3s/server/manifests/` | Auto-deploy manifest directory (Traefik, HelmCharts) |
