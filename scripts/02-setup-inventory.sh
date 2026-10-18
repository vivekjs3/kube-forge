#!/usr/bin/env bash
# ==============================================================================
# 02-setup-inventory.sh — Clone Kubespray and configure cluster inventory
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

KUBESPRAY_TAG="${KUBESPRAY_TAG:-v2.26.0}"

echo "=============================================================================="
echo " kube-forge (kubespray) :: Step 02 - Setup Kubespray & Inventory"
echo "=============================================================================="

# 1. Clone Kubespray
if [[ ! -d "kubespray" ]]; then
    echo "${INFO} Cloning Kubespray (${KUBESPRAY_TAG})..."
    git clone --branch "${KUBESPRAY_TAG}" --depth 1 https://github.com/kubernetes-sigs/kubespray.git
else
    echo "${INFO} kubespray directory already exists."
fi

# 2. Setup inventory directory
INVENTORY_DIR="inventory/mycluster"
mkdir -p "${INVENTORY_DIR}"

if [[ ! -f "${INVENTORY_DIR}/inventory.ini" ]]; then
    echo "${INFO} Copying sample inventory to ${INVENTORY_DIR}/inventory.ini..."
    cp configs/inventory.ini.example "${INVENTORY_DIR}/inventory.ini"
fi

if [[ ! -d "${INVENTORY_DIR}/group_vars" ]]; then
    echo "${INFO} Copying sample group_vars..."
    cp -r kubespray/inventory/sample/group_vars "${INVENTORY_DIR}/"
fi

echo "=============================================================================="
echo "${SUCCESS} Step 02 Kubespray & Inventory Prepared in ${INVENTORY_DIR}/"
echo "${INFO} Review and edit '${INVENTORY_DIR}/inventory.ini' before running 03-deploy-cluster.sh"
echo "=============================================================================="
