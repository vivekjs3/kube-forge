#!/usr/bin/env bash
# ==============================================================================
# 05-apply-worker.sh — Apply machine configuration to a Worker node
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

WORKER_IP="${1:-10.10.10.11}"
CONFIG_FILE="generated/worker.yaml"

echo "=============================================================================="
echo " kube-forge (talos) :: Step 05 - Apply Worker Node Configuration"
echo "=============================================================================="

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "${ERROR} ${CONFIG_FILE} not found. Run '02-generate-configs.sh' first." >&2
    exit 1
fi

echo "${INFO} Applying worker configuration to node at ${WORKER_IP}..."
talosctl apply-config --insecure --nodes "${WORKER_IP}" --file "${CONFIG_FILE}"

echo "=============================================================================="
echo "${SUCCESS} Worker configuration applied to ${WORKER_IP}!"
echo "${INFO} The node will reboot and register as a Kubernetes worker automatically."
echo "=============================================================================="
