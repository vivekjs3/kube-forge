#!/usr/bin/env bash
# ==============================================================================
# tests/test-microk8s-health.sh — Automated health check for MicroK8s
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo ">>> Running MicroK8s Health Diagnostics..."

if ! microk8s status &>/dev/null; then
    echo "${ERROR} MicroK8s is not running or user does not have permission." >&2
    exit 1
fi
echo "${SUCCESS} MicroK8s is active."

NOT_READY=$(microk8s kubectl get nodes --no-headers | grep -v ' Ready ' | wc -l || true)
if [[ "${NOT_READY}" -ne 0 ]]; then
    echo "${ERROR} One or more MicroK8s nodes are NotReady." >&2
    exit 1
fi
echo "${SUCCESS} MicroK8s node is Ready."

echo ">>> MicroK8s Health Diagnostic PASSED!"
