#!/usr/bin/env bash
# ==============================================================================
# 03-install-server.sh — Install and initialize RKE2 Server
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (rke2) :: Step 03 - RKE2 Server Installation"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n 1 || hostname -I | awk '{print $1}')
echo "${INFO} Primary Server IP: ${SERVER_IP}"

# 1. Setup config
mkdir -p /etc/rancher/rke2
CONFIG_FILE="/etc/rancher/rke2/config.yaml"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "${INFO} Writing configuration to ${CONFIG_FILE}..."
    cat <<EOF > "${CONFIG_FILE}"
write-kubeconfig-mode: "0644"
tls-san:
  - "${SERVER_IP}"
  - "127.0.0.1"
  - "localhost"
EOF
    echo "${SUCCESS} Created ${CONFIG_FILE}."
fi

# 2. Run installer
echo "${INFO} Downloading and executing official RKE2 installer..."
curl -sfL https://get.rke2.io | sh -

# 3. Start Service
echo "${INFO} Enabling and starting rke2-server service..."
systemctl daemon-reload
systemctl enable --now rke2-server

echo "${INFO} Waiting for rke2-server service to become active and generate token..."
for i in {1..45}; do
    if systemctl is-active --quiet rke2-server && [[ -f /var/lib/rancher/rke2/server/node-token ]]; then
        echo "${SUCCESS} rke2-server service is active!"
        break
    fi
    sleep 2
done

TOKEN=$(cat /var/lib/rancher/rke2/server/node-token)
echo ""
echo "=============================================================================="
echo " RKE2 AGENT REGISTRATION TOKEN:"
echo " ${TOKEN}"
echo "=============================================================================="
echo "${INFO} Join command for agents:"
echo "sudo ./scripts/05-join-agents.sh https://${SERVER_IP}:9345 ${TOKEN}"
echo "=============================================================================="
