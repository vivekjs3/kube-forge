#!/usr/bin/env bash
# ==============================================================================
# 04-generate-kubeconfigs.sh — Generate kubeconfig files for all components
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (hardway) :: Step 04 - Generate Component Kubeconfigs"
echo "=============================================================================="

KUBERNETES_PUBLIC_ADDRESS="${1:-10.10.10.10}"
PKI_DIR="tls"
KUBECONFIG_DIR="kubeconfigs"

mkdir -p "${KUBECONFIG_DIR}"

if [[ ! -f "${PKI_DIR}/ca.pem" ]]; then
    echo "${ERROR} CA certificates not found in ${PKI_DIR}. Run '03-generate-pki.sh' first." >&2
    exit 1
fi

# Function to generate a kubeconfig
generate_kubeconfig() {
    local instance="$1"
    local cert="$2"
    local key="$3"
    local user="$4"
    local output="${KUBECONFIG_DIR}/${instance}.kubeconfig"

    echo "${INFO} Generating ${output}..."

    kubectl config set-cluster kubernetes-the-hard-way \
        --certificate-authority="${PKI_DIR}/ca.pem" \
        --embed-certs=true \
        --server="https://${KUBERNETES_PUBLIC_ADDRESS}:6443" \
        --kubeconfig="${output}"

    kubectl config set-credentials "${user}" \
        --client-certificate="${PKI_DIR}/${cert}" \
        --client-key="${PKI_DIR}/${key}" \
        --embed-certs=true \
        --kubeconfig="${output}"

    kubectl config set-context default \
        --cluster=kubernetes-the-hard-way \
        --user="${user}" \
        --kubeconfig="${output}"

    kubectl config use-context default --kubeconfig="${output}"
}

# 1. Kubelet (k8s-worker-01)
generate_kubeconfig "k8s-worker-01" "k8s-worker-01.pem" "k8s-worker-01-key.pem" "system:node:k8s-worker-01"

# 2. kube-proxy
generate_kubeconfig "kube-proxy" "kube-proxy.pem" "kube-proxy-key.pem" "system:kube-proxy"

# 3. kube-controller-manager
generate_kubeconfig "kube-controller-manager" "kube-controller-manager.pem" "kube-controller-manager-key.pem" "system:kube-controller-manager"

# 4. kube-scheduler
generate_kubeconfig "kube-scheduler" "kube-scheduler.pem" "kube-scheduler-key.pem" "system:kube-scheduler"

# 5. admin
generate_kubeconfig "admin" "admin.pem" "admin-key.pem" "admin"

echo "=============================================================================="
echo "${SUCCESS} Step 04 Component Kubeconfigs Generated in ${KUBECONFIG_DIR}!"
echo "=============================================================================="
