#!/usr/bin/env bash
# ==============================================================================
# tests/test-kubespray-health.sh — Automated health check for Kubespray cluster
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo ">>> Running Kubespray Cluster Health Diagnostic Suite..."

if ! kubectl cluster-info &>/dev/null; then
    echo "${ERROR} Cannot connect to Kubernetes API server. Check KUBECONFIG." >&2
    exit 1
fi
echo "${SUCCESS} API server is reachable."

NOT_READY=$(kubectl get nodes --no-headers | grep -v ' Ready ' | wc -l || true)
if [[ "${NOT_READY}" -ne 0 ]]; then
    echo "${ERROR} One or more nodes in the Kubespray cluster are NotReady." >&2
    kubectl get nodes
    exit 1
fi
echo "${SUCCESS} All nodes are in Ready state."

echo ">>> Kubespray Health Diagnostic PASSED!"
