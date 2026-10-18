#!/usr/bin/env bash
# ==============================================================================
# 05-validate.sh — Validate Kubespray cluster health & workload deployment
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (kubespray) :: Step 05 - End-to-End Validation"
echo "=============================================================================="

# Ensure kubeconfig
if [[ -z "${KUBECONFIG:-}" && -f "$HOME/.kube/config" ]]; then
    export KUBECONFIG="$HOME/.kube/config"
fi

# 1. Nodes Check
echo "${INFO} 1. Checking Registered Nodes:"
kubectl get nodes -o wide

# 2. System Pods Check
echo ""
echo "${INFO} 2. Checking kube-system Pods:"
kubectl get pods -n kube-system -o wide

# 3. Deploy Test Workload
echo ""
echo "${INFO} 3. Deploying Test Workload..."
TEST_MANIFEST="$(dirname "$0")/../examples/test-workload.yaml"

if [[ -f "${TEST_MANIFEST}" ]]; then
    kubectl apply -f "${TEST_MANIFEST}"
    echo "${INFO} Waiting for test workload rollout..."
    kubectl rollout status deployment/nginx-kubespray-test -n default --timeout=120s
    echo "${INFO} Cleaning up test workload..."
    kubectl delete -f "${TEST_MANIFEST}" --ignore-not-found=true
fi

echo "=============================================================================="
echo "${SUCCESS} Kubespray Cluster Validation Completed Successfully!"
echo "=============================================================================="
