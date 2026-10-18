#!/usr/bin/env bash
# ==============================================================================
# 04-configure.sh — Configure user environment and verify kubectl for K3s
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (k3s) :: Step 04 - Configure User Environment"
echo "=============================================================================="

K3S_CONFIG="/etc/rancher/k3s/k3s.yaml"

if [[ ! -f "${K3S_CONFIG}" ]]; then
    echo "${ERROR} ${K3S_CONFIG} not found. Run '03-install-server.sh' first." >&2
    exit 1
fi

# Setup $HOME/.kube/config
mkdir -p "$HOME/.kube"
cp "${K3S_CONFIG}" "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"
echo "${SUCCESS} Copied kubeconfig to $HOME/.kube/config with 0600 permissions."

# Verify cluster connectivity
if kubectl get nodes &>/dev/null; then
    echo "${SUCCESS} kubectl connection verified successfully!"
    kubectl get nodes -o wide
else
    echo "${WARN} Could not immediately connect via kubectl. Checking service..."
    sudo systemctl status k3s --no-pager
fi

echo "=============================================================================="
echo "${SUCCESS} Step 04 User Configuration Completed!"
echo "=============================================================================="
