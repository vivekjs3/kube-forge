#!/usr/bin/env bash
# ==============================================================================
# 03-apply-controlplane.sh — Apply machine configuration to Control Plane node
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

NODE_IP="${1:-10.10.10.10}"
CONFIG_FILE="generated/controlplane.yaml"

echo "=============================================================================="
echo " kube-forge (talos) :: Step 03 - Apply Control Plane Configuration"
echo "=============================================================================="

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "${ERROR} ${CONFIG_FILE} not found. Run '02-generate-configs.sh' first." >&2
    exit 1
fi

echo "${INFO} Applying configuration to node at ${NODE_IP} (insecure maintenance mode)..."
talosctl apply-config --insecure --nodes "${NODE_IP}" --file "${CONFIG_FILE}"

echo "=============================================================================="
echo "${SUCCESS} Configuration applied to ${NODE_IP}!"
echo "${INFO} The node will now install Talos and start etcd in standby mode."
echo "=============================================================================="
