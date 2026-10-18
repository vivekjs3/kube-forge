#!/usr/bin/env bash
# ==============================================================================
# 05-install-etcd.sh — Download, configure, and start native etcd systemd service
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

ETCD_VER="v3.5.15"
ARCH=$(dpkg --print-architecture)

echo "=============================================================================="
echo " kube-forge (hardway) :: Step 05 - Install & Bootstrap etcd Cluster"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Download etcd
if ! command -v etcd &>/dev/null; then
    echo "${INFO} Downloading etcd ${ETCD_VER}..."
    wget -q --show-progress "https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz"
    tar -xvf "etcd-${ETCD_VER}-linux-${ARCH}.tar.gz"
    mv "etcd-${ETCD_VER}-linux-${ARCH}/etcd"* /usr/local/bin/
    rm -rf "etcd-${ETCD_VER}-linux-${ARCH}"*
fi
echo "${SUCCESS} etcd binaries installed in /usr/local/bin/."

# 2. Configure etcd certificates & state directory
mkdir -p /etc/etcd /var/lib/etcd
chmod 700 /var/lib/etcd

if [[ -f tls/ca.pem && -f tls/kubernetes.pem ]]; then
    cp tls/ca.pem tls/kubernetes.pem tls/kubernetes-key.pem /etc/etcd/
    chmod 600 /etc/etcd/*-key.pem
    chmod 644 /etc/etcd/*.pem
fi

# 3. Create systemd service unit
INTERNAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n 1 || hostname -I | awk '{print $1}')
ETCD_NAME="k8s-control-01"

echo "${INFO} Writing /etc/systemd/system/etcd.service..."
cat <<EOF > /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-token \\
  --initial-cluster ${ETCD_NAME}=https://${INTERNAL_IP}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 4. Start etcd
systemctl daemon-reload
systemctl enable --now etcd

echo "${INFO} Waiting for etcd to start..."
sleep 3

# 5. Verify etcd
ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem

echo "=============================================================================="
echo "${SUCCESS} Step 05 etcd Service Active and Healthy!"
echo "=============================================================================="
