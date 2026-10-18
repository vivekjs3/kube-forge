#!/usr/bin/env bash
# ==============================================================================
# 04-scale-worker.sh — Scale cluster by joining new worker node via scale.yml
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

NODE_NAME="${1:-}"

echo "=============================================================================="
echo " kube-forge (kubespray) :: Step 04 - Scale Worker Nodes"
echo "=============================================================================="

if [[ -z "${NODE_NAME}" ]]; then
    echo "${ERROR} Please specify the hostname of the new worker node."
    echo "Usage: ./scripts/04-scale-worker.sh <WORKER_HOSTNAME>"
    exit 1
fi

# shellcheck disable=SC1091
if [[ -f "venv/bin/activate" ]]; then
    source venv/bin/activate
fi

INVENTORY="inventory/mycluster/inventory.ini"

echo "${INFO} Scaling cluster: adding node '${NODE_NAME}'..."
ansible-playbook -i "${INVENTORY}" kubespray/scale.yml --limit="${NODE_NAME}" -b -v

echo "=============================================================================="
echo "${SUCCESS} Node '${NODE_NAME}' successfully added to cluster!"
echo "=============================================================================="
