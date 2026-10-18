#!/usr/bin/env bash
# ==============================================================================
# 03-install-server.sh — Install and initialize K3s Server
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

K3S_VERSION="${K3S_VERSION:-}"

echo "=============================================================================="
echo " kube-forge (k3s) :: Step 03 - K3s Server Installation"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# Detect Server IP
SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n 1 || hostname -I | awk '{print $1}')
echo "${INFO} Primary Server IP: ${SERVER_IP}"

# 1. Setup declarative configuration directory
mkdir -p /etc/rancher/k3s
CONFIG_FILE="/etc/rancher/k3s/config.yaml"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "${INFO} Writing declarative configuration to ${CONFIG_FILE}..."
    cat <<EOF > "${CONFIG_FILE}"
write-kubeconfig-mode: "0644"
tls-san:
  - "${SERVER_IP}"
  - "127.0.0.1"
  - "localhost"
EOF
    echo "${SUCCESS} Created ${CONFIG_FILE}."
else
    echo "${INFO} Existing ${CONFIG_FILE} detected. Preserving configuration."
fi

# 2. Execute Official K3s Installer
echo "${INFO} Downloading and executing official K3s installer..."
INSTALL_ARGS=()
if [[ -n "${K3S_VERSION}" ]]; then
    export INSTALL_K3S_VERSION="${K3S_VERSION}"
fi

curl -sfL https://get.k3s.io | sh -s - server

# 3. Wait for Service
echo "${INFO} Waiting for k3s service to become active..."
systemctl daemon-reload
systemctl enable --now k3s

for i in {1..30}; do
    if systemctl is-active --quiet k3s && [[ -f /var/lib/rancher/k3s/server/node-token ]]; then
        echo "${SUCCESS} k3s service is active and running!"
        break
    fi
    sleep 2
done

# 4. Display Token
TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
echo ""
echo "=============================================================================="
echo " K3S AGENT REGISTRATION TOKEN:"
echo " ${TOKEN}"
echo "=============================================================================="
echo "${INFO} Join command for agents:"
echo "sudo ./scripts/05-join-agents.sh https://${SERVER_IP}:6443 ${TOKEN}"
echo "=============================================================================="
