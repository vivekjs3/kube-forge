#!/usr/bin/env bash
# ==============================================================================
# 07-install-worker.sh — Install Container Runtime, Kubelet, and Kube-Proxy
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

K8S_VER="v1.31.0"
CNI_VER="v1.5.1"
ARCH=$(dpkg --print-architecture)

echo "=============================================================================="
echo " kube-forge (hardway) :: Step 07 - Worker Node Binary & Systemd Installation"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Directories
mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes

# 2. Download CNI plugins
if [[ ! -f /opt/cni/bin/bridge ]]; then
    echo "${INFO} Downloading CNI plugins ${CNI_VER}..."
    wget -q --show-progress "https://github.com/containernetworking/plugins/releases/download/${CNI_VER}/cni-plugins-linux-${ARCH}-${CNI_VER}.tgz"
    tar -xvf "cni-plugins-linux-${ARCH}-${CNI_VER}.tgz" -C /opt/cni/bin/
    rm -f "cni-plugins-linux-${ARCH}-${CNI_VER}.tgz"
fi

# 3. Download Kubelet & Kube-Proxy
for bin in kubelet kube-proxy; do
    if ! command -v "$bin" &>/dev/null; then
        echo "${INFO} Downloading ${bin} ${K8S_VER}..."
        wget -q --show-progress "https://dl.k8s.io/${K8S_VER}/bin/linux/${ARCH}/${bin}"
        chmod +x "${bin}"
        mv "${bin}" /usr/local/bin/
    fi
done

# 4. Install containerd via apt or binary
if ! command -v containerd &>/dev/null; then
    echo "${INFO} Installing containerd runtime..."
    apt-get update -y && apt-get install -y containerd
fi

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl daemon-reload
systemctl restart containerd
systemctl enable containerd

# 5. Configure CNI Bridge (Pod Subnet: 10.200.0.0/24)
POD_CIDR="10.200.0.0/24"
cat <<EOF > /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "1.0.0",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cbr0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF

cat <<EOF > /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "1.0.0",
    "name": "lo",
    "type": "loopback"
}
EOF

# 6. Copy Kubelet & Proxy certs and kubeconfigs
HOSTNAME="k8s-worker-01"
if [[ -f tls/ca.pem ]]; then
    cp tls/ca.pem /var/lib/kubernetes/
fi
if [[ -f tls/${HOSTNAME}.pem ]]; then
    cp tls/${HOSTNAME}.pem /var/lib/kubelet/
    cp tls/${HOSTNAME}-key.pem /var/lib/kubelet/
fi
if [[ -f kubeconfigs/${HOSTNAME}.kubeconfig ]]; then
    cp kubeconfigs/${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
fi
if [[ -f kubeconfigs/kube-proxy.kubeconfig ]]; then
    cp kubeconfigs/kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
fi

# 7. Kubelet Configuration
cat <<EOF > /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
cgroupDriver: systemd
containerRuntimeEndpoint: "unix:///run/containerd/containerd.sock"
failSwapOn: false
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
EOF

# 8. Kubelet Systemd Unit
cat <<EOF > /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 9. Kube-Proxy Configuration & Systemd Unit
cat <<EOF > /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF

cat <<EOF > /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 10. Start Worker Services
systemctl daemon-reload
systemctl enable --now kubelet kube-proxy

echo "${INFO} Waiting for worker daemons to register..."
sleep 5

echo "=============================================================================="
echo "${SUCCESS} Step 07 Worker Daemons (Kubelet & Kube-Proxy) Active!"
echo "=============================================================================="
