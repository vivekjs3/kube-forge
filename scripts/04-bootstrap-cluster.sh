#!/usr/bin/env bash
# ==============================================================================
# 04-bootstrap-cluster.sh — Bootstrap etcd and fetch cluster kubeconfig
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

NODE_IP="${1:-10.10.10.10}"
TALOSCONFIG="generated/talosconfig"

echo "=============================================================================="
echo " kube-forge (talos) :: Step 04 - Bootstrap Cluster & Retrieve Kubeconfig"
echo "=============================================================================="

if [[ ! -f "${TALOSCONFIG}" ]]; then
    echo "${ERROR} ${TALOSCONFIG} not found. Run '02-generate-configs.sh' first." >&2
    exit 1
fi

echo "${INFO} Sending bootstrap command to control plane at ${NODE_IP}..."
talosctl bootstrap \
    --nodes "${NODE_IP}" \
    --endpoints "${NODE_IP}" \
    --talosconfig "${TALOSCONFIG}"

echo "${INFO} Waiting for Kubernetes control plane to initialize..."
sleep 15

# Retrieve kubeconfig
echo "${INFO} Fetching kubeconfig..."
mkdir -p "$HOME/.kube"
talosctl kubeconfig "$HOME/.kube/config" \
    --nodes "${NODE_IP}" \
    --endpoints "${NODE_IP}" \
    --talosconfig "${TALOSCONFIG}" \
    --force

echo "=============================================================================="
echo "${SUCCESS} Cluster bootstrapped and kubeconfig retrieved to ~/.kube/config!"
echo "=============================================================================="
