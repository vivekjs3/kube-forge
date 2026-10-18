#!/usr/bin/env bash
# ==============================================================================
# 06-validate.sh — End-to-end RKE2 cluster validation & workload test
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (rke2) :: Step 06 - End-to-End Validation"
echo "=============================================================================="

KUBECTL_BIN="/var/lib/rancher/rke2/bin/kubectl"
if ! command -v "${KUBECTL_BIN}" &>/dev/null && command -v kubectl &>/dev/null; then
    KUBECTL_BIN="kubectl"
fi

# Ensure KUBECONFIG
if [[ -z "${KUBECONFIG:-}" ]]; then
    if [[ -f "$HOME/.kube/config" ]]; then
        export KUBECONFIG="$HOME/.kube/config"
    elif [[ -f "/etc/rancher/rke2/rke2.yaml" ]]; then
        export KUBECONFIG="/etc/rancher/rke2/rke2.yaml"
    else
        echo "${ERROR} No kubeconfig found. Run '04-configure.sh' first." >&2
        exit 1
    fi
fi

# 1. Nodes Check
echo "${INFO} 1. Checking Node Status:"
"${KUBECTL_BIN}" get nodes -o wide

# 2. System Pods Check
echo ""
echo "${INFO} 2. Checking RKE2 System Pods in kube-system:"
"${KUBECTL_BIN}" get pods -n kube-system -o wide

# 3. Deploy Test Workload
echo ""
echo "${INFO} 3. Deploying Test Workload..."
TEST_MANIFEST="$(dirname "$0")/../examples/test-workload.yaml"

if [[ ! -f "${TEST_MANIFEST}" ]]; then
    echo "${ERROR} Manifest not found at ${TEST_MANIFEST}" >&2
    exit 1
fi

"${KUBECTL_BIN}" apply -f "${TEST_MANIFEST}"

echo "${INFO} Waiting for test workload rollout..."
"${KUBECTL_BIN}" rollout status deployment/nginx-rke2-test -n default --timeout=120s

# 4. Cleanup
echo ""
echo "${INFO} 4. Cleaning up test workload..."
"${KUBECTL_BIN}" delete -f "${TEST_MANIFEST}" --ignore-not-found=true

echo "=============================================================================="
echo "${SUCCESS} RKE2 Validation Completed Successfully!"
echo "=============================================================================="
