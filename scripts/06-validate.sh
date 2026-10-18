#!/usr/bin/env bash
# ==============================================================================
# 06-validate.sh — End-to-end cluster validation for MicroK8s
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (microk8s) :: Step 06 - End-to-End Validation"
echo "=============================================================================="

# 1. MicroK8s Readiness
echo "${INFO} 1. Checking MicroK8s readiness..."
microk8s status --wait-ready

# 2. Nodes Check
echo ""
echo "${INFO} 2. Checking Registered Nodes:"
microk8s kubectl get nodes -o wide

# 3. System Pods Check
echo ""
echo "${INFO} 3. Checking Pods in kube-system & ingress:"
microk8s kubectl get pods -A

# 4. Deploy Test Workload
echo ""
echo "${INFO} 4. Deploying Test Workload..."
TEST_MANIFEST="$(dirname "$0")/../examples/test-workload.yaml"

if [[ -f "${TEST_MANIFEST}" ]]; then
    microk8s kubectl apply -f "${TEST_MANIFEST}"
    echo "${INFO} Waiting for test workload rollout..."
    microk8s kubectl rollout status deployment/nginx-microk8s-test -n default --timeout=90s
    echo "${INFO} Cleaning up test workload..."
    microk8s kubectl delete -f "${TEST_MANIFEST}" --ignore-not-found=true
fi

echo "=============================================================================="
echo "${SUCCESS} MicroK8s Cluster Validation Completed Successfully!"
echo "=============================================================================="
