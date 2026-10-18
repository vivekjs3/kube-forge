# Kubeadm Architecture Deep Dive

This document details the mechanics of kubeadm cluster lifecycle, state storage, and static pod bootstrapping.

---

## 1. Static Pod Bootstrapping Sequence

When `kubeadm init` runs, it prepares the node without relying on a pre-existing Kubernetes cluster:

1. **Host Preparation:** Kubelet is installed via system package manager and managed by systemd.
2. **Kubelet Standalone Mode:** Before joining a cluster, `kubelet` is directed to watch `/etc/kubernetes/manifests/`.
3. **Manifest Injection:** `kubeadm` writes four Pod YAML files into that directory:
   - `etcd.yaml`
   - `kube-apiserver.yaml`
   - `kube-controller-manager.yaml`
   - `kube-scheduler.yaml`
4. **CRI Invocation:** Kubelet notices the manifests and instructs the local CRI daemon (`containerd`) via the Unix socket `/run/containerd/containerd.sock` to create container sandboxes.
5. **Self-Hosting API:** Once `kube-apiserver` is listening on `6443`, the kubelet transitions from standalone manifest watcher into a fully authenticated cluster node agent reporting to the API server.

---

## 2. Directory Structure on Control Plane

```text
/etc/kubernetes/
├── admin.conf                # Root administrative kubeconfig
├── controller-manager.conf   # Service account kubeconfig for controller-manager
├── kubelet.conf              # Node identity kubeconfig for kubelet
├── scheduler.conf            # Scheduler identity kubeconfig
├── manifests/
│   ├── etcd.yaml             # Static pod manifest for etcd
│   ├── kube-apiserver.yaml   # Static pod manifest for API server
│   ├── kube-controller-manager.yaml
│   └── kube-scheduler.yaml
└── pki/
    ├── ca.crt & ca.key       # Cluster Root CA
    ├── apiserver.crt & key   # API Server mTLS cert with SANs
    ├── apiserver-kubelet-client.crt & key
    ├── front-proxy-ca.crt & key
    ├── sa.key & sa.pub       # RSA Keypair for signing ServiceAccount tokens
    └── etcd/
        ├── ca.crt & ca.key   # Dedicated etcd CA
        ├── server.crt & key
        └── peer.crt & key
```
