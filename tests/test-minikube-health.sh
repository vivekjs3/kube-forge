#!/usr/bin/env bash
# ==============================================================================
# tests/test-minikube-health.sh — Automated health check for Minikube
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo ">>> Running Minikube Health Diagnostics..."

# 1. Minikube status
if ! minikube status &>/dev/null; then
    echo "${ERROR} Minikube cluster is not running." >&2
    exit 1
fi
echo "${SUCCESS} Minikube status is Running."

# 2. Node Status
NOT_READY=$(kubectl get nodes --no-headers | grep -v ' Ready ' | wc -l || true)
if [[ "${NOT_READY}" -ne 0 ]]; then
    echo "${ERROR} Minikube node is NotReady." >&2
    exit 1
fi
echo "${SUCCESS} Minikube node is Ready."

echo ">>> Minikube Health Diagnostic PASSED!"
