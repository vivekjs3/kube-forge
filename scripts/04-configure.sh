#!/usr/bin/env bash
# ==============================================================================
# 04-configure.sh — Configure user environment and verify kubectl for RKE2
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (rke2) :: Step 04 - Configure User Environment"
echo "=============================================================================="

RKE2_KUBECONFIG="/etc/rancher/rke2/rke2.yaml"
RKE2_BIN="/var/lib/rancher/rke2/bin"

if [[ ! -f "${RKE2_KUBECONFIG}" ]]; then
    echo "${ERROR} ${RKE2_KUBECONFIG} not found. Run '03-install-server.sh' first." >&2
    exit 1
fi

# Link binary if needed
if [[ -f "${RKE2_BIN}/kubectl" && ! -f /usr/local/bin/kubectl ]]; then
    echo "${INFO} Symlinking RKE2 kubectl to /usr/local/bin/kubectl..."
    sudo ln -s "${RKE2_BIN}/kubectl" /usr/local/bin/kubectl || true
fi

# Setup kubeconfig
mkdir -p "$HOME/.kube"
cp "${RKE2_KUBECONFIG}" "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"
echo "${SUCCESS} Configured $HOME/.kube/config."

export KUBECONFIG="$HOME/.kube/config"
export PATH="${PATH}:${RKE2_BIN}"

if "${RKE2_BIN}/kubectl" get nodes &>/dev/null; then
    echo "${SUCCESS} kubectl connection verified!"
    "${RKE2_BIN}/kubectl" get nodes -o wide
else
    echo "${WARN} Waiting for API server to become ready..."
fi

echo "=============================================================================="
echo "${SUCCESS} Step 04 User Configuration Completed!"
echo "=============================================================================="
