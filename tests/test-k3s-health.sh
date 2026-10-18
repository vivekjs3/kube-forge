#!/usr/bin/env bash
# ==============================================================================
# tests/test-k3s-health.sh — Automated health check for K3s
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo ">>> Running K3s Health Diagnostic Suite..."

# 1. Check API Connectivity
if ! kubectl get nodes &>/dev/null; then
    echo "${ERROR} Cannot connect to K3s cluster. Check KUBECONFIG." >&2
    exit 1
fi
echo "${SUCCESS} K3s API server is reachable."

# 2. Check Node Status
NOT_READY=$(kubectl get nodes --no-headers | grep -v ' Ready ' | wc -l || true)
if [[ "${NOT_READY}" -ne 0 ]]; then
    echo "${ERROR} One or more K3s nodes are NotReady." >&2
    kubectl get nodes
    exit 1
fi
echo "${SUCCESS} All K3s nodes are Ready."

# 3. Check System Pods
FAILED=$(kubectl get pods -n kube-system --no-headers | grep -v 'Running' | grep -v 'Completed' | wc -l || true)
if [[ "${FAILED}" -ne 0 ]]; then
    echo "${WARN} Found ${FAILED} pod(s) in kube-system not in Running/Completed state:"
    kubectl get pods -n kube-system | grep -v 'Running' | grep -v 'Completed'
else
    echo "${SUCCESS} All kube-system pods are Running or Completed."
fi

echo ">>> K3s Health Diagnostic PASSED!"
