# Kubernetes The Hard Way: Prerequisites

Before embarking on manual binary installation, ensure all required tools, hardware, and kernel settings are present.

---

## 1. Hardware Requirements

| Node Type | Minimum vCPU | Recommended vCPU | Minimum RAM | Recommended RAM |
|---|---|---|---|---|
| **Control Plane** | 2 vCPU | 2-4 vCPU | 2 GB | 4 GB |
| **Worker Node** | 1 vCPU | 2 vCPU | 1.5 GB | 2 GB |

---

## 2. PKI Tooling: `cfssl` and `cfssljson`

Manual certificate generation requires Cloudflare's PKI toolkit (`cfssl` and `cfssljson`):
```bash
sudo curl -s -L -o /usr/local/bin/cfssl https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssl_1.6.5_linux_amd64
sudo curl -s -L -o /usr/local/bin/cfssljson https://github.com/cloudflare/cfssl/releases/download/v1.6.5/cfssljson_1.6.5_linux_amd64
sudo chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson
```

---

## 3. Kernel Modules & Sysctl Settings

```bash
sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/99-kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

---

## 4. Upstream Component Binaries

All binaries used in this lab are official release binaries downloaded directly from CNCF / Kubernetes release repositories:
- **Kubernetes Binaries:** `https://dl.k8s.io/v1.31.0/bin/linux/amd64/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kubelet,kube-proxy}`
- **etcd:** `https://github.com/etcd-io/etcd/releases/download/v3.5.15/etcd-v3.5.15-linux-amd64.tar.gz`
- **containerd:** `https://github.com/containerd/containerd/releases/`
- **CNI Plugins:** `https://github.com/containernetworking/plugins/releases/`
