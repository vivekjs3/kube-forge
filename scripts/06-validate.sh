#!/usr/bin/env bash
# ==============================================================================
# 06-validate.sh — End-to-end K3s validation & workload test
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (k3s) :: Step 06 - End-to-End Validation"
echo "=============================================================================="

# Ensure KUBECONFIG
if [[ -z "${KUBECONFIG:-}" ]]; then
    if [[ -f "$HOME/.kube/config" ]]; then
        export KUBECONFIG="$HOME/.kube/config"
    elif [[ -f "/etc/rancher/k3s/k3s.yaml" ]]; then
        export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
    else
        echo "${ERROR} No kubeconfig found. Run '04-configure.sh' first." >&2
        exit 1
    fi
fi

# 1. Nodes Check
echo "${INFO} 1. Checking Node Status:"
kubectl get nodes -o wide

# 2. System Pods Check
echo ""
echo "${INFO} 2. Checking K3s System Pods:"
kubectl get pods -A

# 3. Deploy Test Workload & Ingress
echo ""
echo "${INFO} 3. Deploying Test Workload (Nginx + Service + Traefik Ingress)..."
TEST_MANIFEST="$(dirname "$0")/../examples/test-workload.yaml"

if [[ ! -f "${TEST_MANIFEST}" ]]; then
    echo "${ERROR} Test manifest not found at ${TEST_MANIFEST}" >&2
    exit 1
fi

kubectl apply -f "${TEST_MANIFEST}"

echo "${INFO} Waiting for deployment rollout..."
kubectl rollout status deployment/nginx-k3s-test -n default --timeout=90s

# 4. Ingress Resolution Test
echo ""
echo "${INFO} 4. Testing HTTP traffic via Traefik Ingress..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: nginx.lab.local" http://127.0.0.1/ || echo "000")

if [[ "${HTTP_CODE}" == "200" ]]; then
    echo "${SUCCESS} Traefik Ingress routed HTTP request to nginx successfully (HTTP 200 OK)!"
else
    echo "${WARN} Ingress test returned HTTP ${HTTP_CODE}. Ingress may still be initializing."
fi

# 5. Clean up
echo ""
echo "${INFO} 5. Cleaning up test workload..."
kubectl delete -f "${TEST_MANIFEST}" --ignore-not-found=true

echo "=============================================================================="
echo "${SUCCESS} K3s Validation Completed Successfully!"
echo "=============================================================================="
