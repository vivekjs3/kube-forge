#!/usr/bin/env bash
# ==============================================================================
# reset.sh — Teardown cluster using Kubespray's reset.yml playbook
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

FORCE="${1:-}"

echo "=============================================================================="
echo " kube-forge (kubespray) :: Cluster Teardown (reset.yml)"
echo "=============================================================================="

if [[ "${FORCE}" != "--force" && "${FORCE}" != "-f" ]]; then
    echo ""
    echo "${WARN} WARNING: This operation will execute reset.yml on all target nodes."
    echo "  - All running containers and Pods will be terminated"
    echo "  - All etcd cluster data will be destroyed"
    echo "  - Container runtimes and network bridges will be purged"
    echo ""
    read -rp "Are you sure you want to proceed with cluster reset? [y/N]: " CONFIRM
    if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
        echo "${INFO} Reset aborted."
        exit 0
    fi
fi

# shellcheck disable=SC1091
if [[ -f "venv/bin/activate" ]]; then
    source venv/bin/activate
fi

INVENTORY="inventory/mycluster/inventory.ini"
if [[ ! -f "${INVENTORY}" ]]; then
    echo "${ERROR} Inventory ${INVENTORY} not found." >&2
    exit 1
fi

echo "${INFO} Running Kubespray reset.yml playbook across target fleet..."
ansible-playbook -i "${INVENTORY}" kubespray/reset.yml -b -v -e reset_confirmation=yes

echo "=============================================================================="
echo "${SUCCESS} All nodes reset cleanly by Kubespray!"
echo "=============================================================================="
