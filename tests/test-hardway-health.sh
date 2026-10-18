#!/usr/bin/env bash
# ==============================================================================
# tests/test-hardway-health.sh — Health verification for manual Hard Way cluster
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo ">>> Running Kubernetes The Hard Way Health Diagnostics..."

if [[ -f kubeconfigs/admin.kubeconfig && -z "${KUBECONFIG:-}" ]]; then
    export KUBECONFIG="kubeconfigs/admin.kubeconfig"
fi

# 1. Check systemd units
for svc in etcd kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy containerd; do
    if systemctl is-active --quiet "${svc}"; then
        echo "${SUCCESS} ${svc} is active."
    else
        echo "${WARN} ${svc} is not running."
    fi
done

# 2. Check API Server
if kubectl get nodes &>/dev/null; then
    echo "${SUCCESS} Kubernetes API Server responded successfully."
    kubectl get nodes -o wide
else
    echo "${ERROR} Cannot reach Kubernetes API server." >&2
    exit 1
fi

echo ">>> Kubernetes The Hard Way Health Diagnostic PASSED!"
