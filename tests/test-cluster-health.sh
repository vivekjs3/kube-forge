#!/usr/bin/env bash
# ==============================================================================
# tests/test-cluster-health.sh — Automated cluster health & smoke test
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo ">>> Running kube-forge Cluster Health Diagnostic Suite..."

# 1. API Responsiveness
if ! kubectl version --short &>/dev/null && ! kubectl version &>/dev/null; then
    echo "${ERROR} Unable to reach Kubernetes API server." >&2
    exit 1
fi
echo "${SUCCESS} Kubernetes API server is reachable."

# 2. Check Node Readiness
NOT_READY=$(kubectl get nodes --no-headers | grep -v ' Ready ' | wc -l || true)
if [[ "${NOT_READY}" -ne 0 ]]; then
    echo "${ERROR} Found ${NOT_READY} node(s) in NotReady state!" >&2
    kubectl get nodes
    exit 1
fi
echo "${SUCCESS} All nodes report status Ready."

# 3. Check kube-system Pods
FAILED_PODS=$(kubectl get pods -n kube-system --no-headers | grep -v 'Running' | grep -v 'Completed' | wc -l || true)
if [[ "${FAILED_PODS}" -ne 0 ]]; then
    echo "${WARN} Found ${FAILED_PODS} pod(s) in kube-system not in Running state:"
    kubectl get pods -n kube-system | grep -v 'Running' | grep -v 'Completed'
else
    echo "${SUCCESS} All kube-system pods are Running or Completed."
fi

# 4. Check CoreDNS replicas
COREDNS_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --field-selector=status.phase=Running --no-headers | wc -l)
if [[ "${COREDNS_RUNNING}" -lt 1 ]]; then
    echo "${ERROR} CoreDNS is not running. CNI may not be initialized properly." >&2
    exit 1
fi
echo "${SUCCESS} CoreDNS is active with ${COREDNS_RUNNING} healthy replica(s)."

echo ">>> Cluster Health Diagnostic PASSED!"
