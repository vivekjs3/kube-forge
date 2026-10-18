#!/usr/bin/env bash
# ==============================================================================
# 08-validate.sh — End-to-end cluster validation & workload test
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (kubeadm) :: Step 08 - End-to-End Cluster Validation"
echo "=============================================================================="

# Ensure kubectl is accessible
if [[ -z "${KUBECONFIG:-}" ]]; then
    if [[ -f "$HOME/.kube/config" ]]; then
        export KUBECONFIG="$HOME/.kube/config"
    elif [[ -f "/etc/kubernetes/admin.conf" ]]; then
        export KUBECONFIG="/etc/kubernetes/admin.conf"
    else
        echo "${ERROR} No kubeconfig found. Run '05-init-cluster.sh' first." >&2
        exit 1
    fi
fi

# 1. Cluster Info
echo "${INFO} 1. Testing Cluster Connectivity & API Server Health..."
kubectl cluster-info

# 2. Node Status
echo ""
echo "${INFO} 2. Checking Node Status (All nodes must be 'Ready')..."
kubectl get nodes -o wide

NOT_READY_NODES=$(kubectl get nodes --no-headers | grep -v ' Ready ' | wc -l || true)
if [[ "${NOT_READY_NODES}" -gt 0 ]]; then
    echo "${WARN} Some nodes are not in 'Ready' state. Check CNI status or 'kubectl describe node'."
else
    echo "${SUCCESS} All nodes are in 'Ready' state!"
fi

# 3. System Pods Status
echo ""
echo "${INFO} 3. Inspecting kube-system Pods..."
kubectl get pods -n kube-system -o wide

# 4. Deploy Test Workload
echo ""
echo "${INFO} 4. Deploying Test Workload (Nginx Deployment + Service + Curl Pod)..."
TEST_MANIFEST="$(dirname "$0")/../examples/test-workload.yaml"

if [[ ! -f "${TEST_MANIFEST}" ]]; then
    echo "${ERROR} Manifest not found at ${TEST_MANIFEST}" >&2
    exit 1
fi

kubectl apply -f "${TEST_MANIFEST}"

echo "${INFO} Waiting for test workload deployment to complete rollout..."
kubectl rollout status deployment/nginx-test -n default --timeout=120s

echo "${INFO} Waiting for curl test pod to be Running..."
kubectl wait --for=condition=Ready pod/curl-test -n default --timeout=60s

# 5. Pod-to-Service DNS & Network Communication Test
echo ""
echo "${INFO} 5. Verifying Service Routing & Cluster DNS..."
HTTP_RESPONSE=$(kubectl exec -i curl-test -n default -- curl -s -m 5 http://nginx-service.default.svc.cluster.local:80 || true)

if echo "${HTTP_RESPONSE}" | grep -q "Welcome to nginx!"; then
    echo "${SUCCESS} Pod-to-Service communication and Cluster DNS verified successfully!"
else
    echo "${ERROR} Service HTTP response failed. Output:"
    echo "${HTTP_RESPONSE}"
    exit 1
fi

# 6. Teardown Test Workload
echo ""
echo "${INFO} 6. Cleaning up test workload..."
kubectl delete -f "${TEST_MANIFEST}" --ignore-not-found=true

echo "=============================================================================="
echo "${SUCCESS} Cluster Validation Completed: All tests PASSED!"
echo "=============================================================================="
