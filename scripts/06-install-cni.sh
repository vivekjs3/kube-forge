#!/usr/bin/env bash
# ==============================================================================
# 06-install-cni.sh — Deploy Container Network Interface (Calico or Flannel)
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

CNI_TYPE="${1:-calico}"

echo "=============================================================================="
echo " kube-forge (kubeadm) :: Step 06 - CNI Deployment (${CNI_TYPE})"
echo "=============================================================================="

# Ensure kubectl has access to a kubeconfig
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

# Verify cluster connectivity
if ! kubectl cluster-info &>/dev/null; then
    echo "${ERROR} Cannot connect to Kubernetes API server. Check if the control plane is running." >&2
    exit 1
fi

case "${CNI_TYPE}" in
    calico|--calico)
        echo "${INFO} Installing Tigera Calico CNI operator and custom resources (v3.28)..."
        # 1. Install Tigera Operator
        kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/tigera-operator.yaml 2>/dev/null || \
            kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/tigera-operator.yaml
        
        # 2. Install Custom Resources
        kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/custom-resources.yaml
        
        echo "${INFO} Waiting for calico-node DaemonSet to roll out in calico-system..."
        kubectl rollout status daemonset/calico-node -n calico-system --timeout=180s 2>/dev/null || true
        ;;

    flannel|--flannel)
        echo "${INFO} Installing Flannel CNI (v0.25)..."
        kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
        
        echo "${INFO} Waiting for kube-flannel-ds DaemonSet to roll out in kube-flannel..."
        kubectl rollout status daemonset/kube-flannel-ds -n kube-flannel --timeout=180s 2>/dev/null || true
        ;;

    *)
        echo "${ERROR} Unsupported CNI type: '${CNI_TYPE}'. Use 'calico' or 'flannel'." >&2
        exit 1
        ;;
esac

# Wait for CoreDNS to become Ready
echo "${INFO} Waiting for CoreDNS deployment to become available..."
kubectl wait --namespace=kube-system --for=condition=Available deployment/coredns --timeout=120s 2>/dev/null || true

echo "${INFO} Current Node Status:"
kubectl get nodes -o wide

echo "=============================================================================="
echo "${SUCCESS} Step 06 CNI (${CNI_TYPE}) Installed Successfully!"
echo "=============================================================================="
