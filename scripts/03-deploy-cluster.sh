#!/usr/bin/env bash
# ==============================================================================
# 03-deploy-cluster.sh — Execute Ansible cluster deployment playbook
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (kubespray) :: Step 03 - Cluster Deployment (cluster.yml)"
echo "=============================================================================="

# shellcheck disable=SC1091
if [[ -f "venv/bin/activate" ]]; then
    source venv/bin/activate
fi

INVENTORY="inventory/mycluster/inventory.ini"
if [[ ! -f "${INVENTORY}" ]]; then
    echo "${ERROR} Inventory file not found at ${INVENTORY}. Run '02-setup-inventory.sh' first." >&2
    exit 1
fi

echo "${INFO} Verifying target node connectivity via Ansible ping..."
ansible -i "${INVENTORY}" all -m ping || {
    echo "${ERROR} Cannot ping all target nodes via SSH. Verify SSH keys." >&2
    exit 1
}

echo "${INFO} Launching Kubespray cluster provisioning..."
ansible-playbook -i "${INVENTORY}" kubespray/cluster.yml -b -v

echo "=============================================================================="
echo "${SUCCESS} Kubespray cluster deployment completed successfully!"
echo "=============================================================================="
