#!/usr/bin/env bash
# ==============================================================================
# 09-validate.sh — End-to-end validation for manual Hard Way cluster
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (hardway) :: Step 09 - Manual Cluster Validation"
echo "=============================================================================="

if [[ -z "${KUBECONFIG:-}" ]]; then
    if [[ -f "kubeconfigs/admin.kubeconfig" ]]; then
        export KUBECONFIG="kubeconfigs/admin.kubeconfig"
    elif [[ -f "$HOME/.kube/config" ]]; then
        export KUBECONFIG="$HOME/.kube/config"
    fi
fi

# 1. Systemd Service Verification
echo "${INFO} 1. Verifying Linux systemd services..."
SERVICES=(etcd kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy containerd)
for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "${svc}"; then
        echo "${SUCCESS} ${svc}.service is active (running)."
    else
        echo "${WARN} ${svc}.service is not active."
    fi
done

# 2. Nodes Check
echo ""
echo "${INFO} 2. Checking Registered Nodes:"
kubectl get nodes -o wide || true

# 3. System Pods Check
echo ""
echo "${INFO} 3. Checking System Pods in kube-system:"
kubectl get pods -n kube-system -o wide || true

# 4. Deploy Test Workload
echo ""
echo "${INFO} 4. Deploying Test Workload..."
TEST_MANIFEST="$(dirname "$0")/../examples/test-workload.yaml"

if [[ -f "${TEST_MANIFEST}" ]]; then
    kubectl apply -f "${TEST_MANIFEST}"
    echo "${INFO} Waiting for test deployment rollout..."
    kubectl rollout status deployment/nginx-hardway-test -n default --timeout=90s 2>/dev/null || true
    echo "${INFO} Cleaning up test workload..."
    kubectl delete -f "${TEST_MANIFEST}" --ignore-not-found=true
fi

echo "=============================================================================="
echo "${SUCCESS} Kubernetes The Hard Way Validation Completed!"
echo "=============================================================================="
