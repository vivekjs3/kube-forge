#!/usr/bin/env bash
# ==============================================================================
# 05-join-agents.sh — Install RKE2 agent and join to server
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

SERVER_URL="${1:-}"
NODE_TOKEN="${2:-}"

echo "=============================================================================="
echo " kube-forge (rke2) :: Step 05 - RKE2 Agent Node Join"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root on the worker node." >&2
    exit 1
fi

if [[ -z "${SERVER_URL}" || -z "${NODE_TOKEN}" ]]; then
    echo "${ERROR} Missing arguments!"
    echo "Usage: sudo ./scripts/05-join-agents.sh <SERVER_URL_ON_PORT_9345> <NODE_TOKEN>"
    echo "Example: sudo ./scripts/05-join-agents.sh https://10.10.10.10:9345 K1092a..."
    exit 1
fi

echo "${INFO} Preparing /etc/rancher/rke2/config.yaml on agent node..."
mkdir -p /etc/rancher/rke2
cat <<EOF > /etc/rancher/rke2/config.yaml
server: "${SERVER_URL}"
token: "${NODE_TOKEN}"
EOF

echo "${INFO} Downloading and executing official RKE2 agent installer..."
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -

echo "${INFO} Enabling and starting rke2-agent service..."
systemctl daemon-reload
systemctl enable --now rke2-agent

for i in {1..30}; do
    if systemctl is-active --quiet rke2-agent; then
        echo "${SUCCESS} rke2-agent service is active and running!"
        break
    fi
    sleep 2
done

echo "=============================================================================="
echo "${SUCCESS} Agent joined! Verify on server with 'kubectl get nodes'"
echo "=============================================================================="
