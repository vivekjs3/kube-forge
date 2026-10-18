#!/usr/bin/env bash
# ==============================================================================
# 05-join-agents.sh — Install K3s agent and join to existing server
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

SERVER_URL="${1:-}"
NODE_TOKEN="${2:-}"

echo "=============================================================================="
echo " kube-forge (k3s) :: Step 05 - K3s Agent Node Join"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root on the worker node." >&2
    exit 1
fi

if [[ -z "${SERVER_URL}" || -z "${NODE_TOKEN}" ]]; then
    echo "${ERROR} Missing arguments!"
    echo "Usage: sudo ./scripts/05-join-agents.sh <SERVER_URL> <NODE_TOKEN>"
    echo "Example: sudo ./scripts/05-join-agents.sh https://10.10.10.10:6443 K1092a..."
    exit 1
fi

echo "${INFO} Joining K3s Server at: ${SERVER_URL}..."

# Execute Agent Installer
curl -sfL https://get.k3s.io | K3S_URL="${SERVER_URL}" K3S_TOKEN="${NODE_TOKEN}" sh -s - agent

echo "${INFO} Waiting for k3s-agent service to become active..."
systemctl daemon-reload
systemctl enable --now k3s-agent

for i in {1..30}; do
    if systemctl is-active --quiet k3s-agent; then
        echo "${SUCCESS} k3s-agent is active and connected!"
        break
    fi
    sleep 2
done

echo "=============================================================================="
echo "${SUCCESS} Agent joined successfully! Verify on server with 'kubectl get nodes'"
echo "=============================================================================="
