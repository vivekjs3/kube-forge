#!/usr/bin/env bash
# ==============================================================================
# tests/test-rke2-health.sh — Automated health check for RKE2
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo ">>> Running RKE2 Health Diagnostic Suite..."

KUBECTL_BIN="/var/lib/rancher/rke2/bin/kubectl"
if ! command -v "${KUBECTL_BIN}" &>/dev/null && command -v kubectl &>/dev/null; then
    KUBECTL_BIN="kubectl"
fi

if [[ -f /etc/rancher/rke2/rke2.yaml && -z "${KUBECONFIG:-}" ]]; then
    export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
fi

# 1. API Connectivity
if ! "${KUBECTL_BIN}" get nodes &>/dev/null; then
    echo "${ERROR} Cannot connect to RKE2 cluster API server." >&2
    exit 1
fi
echo "${SUCCESS} RKE2 API server is reachable."

# 2. Nodes Check
NOT_READY=$("${KUBECTL_BIN}" get nodes --no-headers | grep -v ' Ready ' | wc -l || true)
if [[ "${NOT_READY}" -ne 0 ]]; then
    echo "${ERROR} One or more RKE2 nodes are NotReady." >&2
    "${KUBECTL_BIN}" get nodes
    exit 1
fi
echo "${SUCCESS} All RKE2 nodes are Ready."

# 3. System Pods Check
FAILED=$("${KUBECTL_BIN}" get pods -n kube-system --no-headers | grep -v 'Running' | grep -v 'Completed' | wc -l || true)
if [[ "${FAILED}" -ne 0 ]]; then
    echo "${WARN} Found ${FAILED} pod(s) in kube-system not in Running/Completed state:"
    "${KUBECTL_BIN}" get pods -n kube-system | grep -v 'Running' | grep -v 'Completed'
else
    echo "${SUCCESS} All kube-system pods are Running or Completed."
fi

echo ">>> RKE2 Health Diagnostic PASSED!"
