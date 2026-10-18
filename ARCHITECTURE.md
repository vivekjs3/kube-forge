# MicroK8s Architecture & Internal Mechanics

This document details the internal architecture, Snap confinement model, and Dqlite datastore of **MicroK8s**.

---

## 1. Snap Confinement & Filesystem Architecture

MicroK8s packages all components within Canonical's Snap sandbox:

```
+-------------------------------------------------------------------------------+
|                             LINUX HOST OPERATING SYSTEM                       |
|                                                                               |
|   +-----------------------------------------------------------------------+   |
|   |                        snapd (Snap Daemon Manager)                    |   |
|   +-----------------------------------+-----------------------------------+   |
|                                       |                                       |
|                                       v                                       |
|   +-----------------------------------------------------------------------+   |
|   |                       MICROK8S SNAP SANDBOX                           |   |
|   |                                                                       |   |
|   |   Read-Only Binaries Mount: /snap/microk8s/current/                   |   |
|   |   - kube-apiserver, kube-controller-manager, kube-scheduler           |   |
|   |   - kubelet, kube-proxy, containerd, runc, calico                     |   |
|   |                                                                       |   |
|   |   Read-Write State & Config: /var/snap/microk8s/current/              |   |
|   |   - /args/ : Daemon runtime CLI arguments (kube-apiserver, kubelet)   |   |
|   |   - /certs/ : PKI certificates and CAs                                |   |
|   |   - /var/kubernetes/backend/ : Dqlite cluster database                |   |
|   |   - /credentials/ : client.config (kubeconfig)                        |   |
|   +-----------------------------------------------------------------------+   |
+-------------------------------------------------------------------------------+
```

---

## 2. Dqlite: Distributed SQLite Consensus

Unlike standard Kubernetes which requires etcd, MicroK8s uses **Dqlite**:
- Integrates the lightweight C-Raft implementation directly with SQLite.
- Eliminates the heavy JVM/Go runtime memory overhead of etcd while maintaining full ACID transactional guarantees and Raft quorum consensus across clustered nodes.

---

## 3. The MicroK8s Addon Lifecycle

Addons in MicroK8s are modular shell and python scripts located under `/snap/microk8s/current/actions/`:
- When you execute `microk8s enable ingress`:
  1. The hook script validates dependencies.
  2. The addon applies pre-rendered Kubernetes manifests to the cluster using the internal API client.
  3. The status engine flags the addon as active.
