#!/usr/bin/env bash
# ==============================================================================
# 05-validate.sh — End-to-end Minikube cluster validation
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (minikube) :: Step 05 - End-to-End Validation"
echo "=============================================================================="

# 1. Minikube status
echo "${INFO} 1. Checking Minikube status..."
minikube status

# 2. Nodes Check
echo ""
echo "${INFO} 2. Checking Node Readiness:"
kubectl get nodes -o wide

# 3. System Pods Check
echo ""
echo "${INFO} 3. Checking kube-system Pods:"
kubectl get pods -n kube-system

# 4. Deploy Test Workload
echo ""
echo "${INFO} 4. Deploying Test Workload..."
TEST_MANIFEST="$(dirname "$0")/../examples/test-workload.yaml"

if [[ -f "${TEST_MANIFEST}" ]]; then
    kubectl apply -f "${TEST_MANIFEST}"
    echo "${INFO} Waiting for test workload rollout..."
    kubectl rollout status deployment/nginx-minikube-test -n default --timeout=90s
    echo "${INFO} Cleaning up test workload..."
    kubectl delete -f "${TEST_MANIFEST}" --ignore-not-found=true
fi

echo "=============================================================================="
echo "${SUCCESS} Minikube Cluster Validation Completed Successfully!"
echo "=============================================================================="
