#!/usr/bin/env bash
# ==============================================================================
# tests/test-talos-health.sh — Automated health check for Talos cluster
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo ">>> Running Talos Cluster Health Diagnostics..."

# 1. Check kubectl connectivity
if ! kubectl get nodes &>/dev/null; then
    echo "${ERROR} Cannot connect to Kubernetes API server on Talos cluster." >&2
    exit 1
fi
echo "${SUCCESS} Kubernetes API server is reachable."

# 2. Check Node Readiness
NOT_READY=$(kubectl get nodes --no-headers | grep -v ' Ready ' | wc -l || true)
if [[ "${NOT_READY}" -ne 0 ]]; then
    echo "${ERROR} One or more Talos nodes are NotReady." >&2
    kubectl get nodes
    exit 1
fi
echo "${SUCCESS} All Talos nodes report Ready."

echo ">>> Talos Health Diagnostic PASSED!"
