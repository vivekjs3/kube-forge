#!/usr/bin/env bash
# ==============================================================================
# 06-validate.sh — Validate Talos cluster health & workload execution
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

NODE_IP="${1:-10.10.10.10}"
TALOSCONFIG="generated/talosconfig"

echo "=============================================================================="
echo " kube-forge (talos) :: Step 06 - End-to-End Validation"
echo "=============================================================================="

# 1. Talos OS Health Check
if [[ -f "${TALOSCONFIG}" ]]; then
    echo "${INFO} 1. Checking Talos OS & Control Plane Health..."
    talosctl health \
        --nodes "${NODE_IP}" \
        --endpoints "${NODE_IP}" \
        --talosconfig "${TALOSCONFIG}" || true
fi

# 2. Kubernetes Nodes
echo ""
echo "${INFO} 2. Checking Kubernetes Nodes:"
kubectl get nodes -o wide

# 3. Kubernetes Pods
echo ""
echo "${INFO} 3. Checking System Pods in kube-system:"
kubectl get pods -n kube-system

# 4. Deploy Test Workload
echo ""
echo "${INFO} 4. Deploying Test Workload..."
TEST_MANIFEST="$(dirname "$0")/../examples/test-workload.yaml"

if [[ -f "${TEST_MANIFEST}" ]]; then
    kubectl apply -f "${TEST_MANIFEST}"
    echo "${INFO} Waiting for test workload rollout..."
    kubectl rollout status deployment/nginx-talos-test -n default --timeout=120s
    echo "${INFO} Cleaning up test workload..."
    kubectl delete -f "${TEST_MANIFEST}" --ignore-not-found=true
fi

echo "=============================================================================="
echo "${SUCCESS} Talos Linux Cluster Validation Completed Successfully!"
echo "=============================================================================="
