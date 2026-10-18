#!/usr/bin/env bash
# ==============================================================================
# 05-init-cluster.sh — Initialize Kubernetes Control Plane via kubeadm
# Target: Ubuntu 22.04 / 24.04 LTS
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

# Defaults
POD_CIDR="${POD_CIDR:-10.244.0.0/16}"
SERVICE_CIDR="${SERVICE_CIDR:-10.96.0.0/12}"

echo "=============================================================================="
echo " kube-forge (kubeadm) :: Step 05 - Control Plane Initialization"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Determine Advertise IP
DEFAULT_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n 1 || hostname -I | awk '{print $1}')
APISERVER_IP="${APISERVER_ADVERTISE_ADDRESS:-${DEFAULT_IP}}"

echo "${INFO} API Server Advertise Address: ${APISERVER_IP}"
echo "${INFO} Pod Network CIDR:            ${POD_CIDR}"
echo "${INFO} Service Network CIDR:        ${SERVICE_CIDR}"

# Check if cluster is already initialized
if [[ -f /etc/kubernetes/admin.conf ]]; then
    echo "${WARN} /etc/kubernetes/admin.conf already exists. Cluster appears already initialized."
    echo "${INFO} If you wish to re-initialize, run 'sudo ./scripts/reset.sh' first."
    exit 0
fi

# 2. Run kubeadm init
echo "${INFO} Executing kubeadm init..."
kubeadm init \
    --apiserver-advertise-address="${APISERVER_IP}" \
    --pod-network-cidr="${POD_CIDR}" \
    --service-cidr="${SERVICE_CIDR}" \
    --cri-socket="unix:///run/containerd/containerd.sock" \
    --upload-certs

# 3. Configure Kubeconfig for Current Non-Root User
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "${TARGET_USER}" | cut -d: -f6)

echo "${INFO} Setting up kubeconfig for user '${TARGET_USER}' in ${TARGET_HOME}/.kube/config..."
mkdir -p "${TARGET_HOME}/.kube"
cp -f /etc/kubernetes/admin.conf "${TARGET_HOME}/.kube/config"
chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.kube"
chmod 600 "${TARGET_HOME}/.kube/config"

# Also link for root
mkdir -p "$HOME/.kube"
cp -f /etc/kubernetes/admin.conf "$HOME/.kube/config"

echo "${SUCCESS} Kubeconfig successfully created and permissions set."

# 4. Optional: Untaint control plane if single-node cluster
if [[ "${SINGLE_NODE:-false}" == "true" ]]; then
    echo "${INFO} SINGLE_NODE=true detected. Removing control-plane taint to allow scheduling workloads..."
    export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl taint nodes --all node-role.kubernetes.io/control-plane- 2>/dev/null || true
    echo "${SUCCESS} Control plane node untainted."
fi

echo "=============================================================================="
echo "${SUCCESS} Control Plane initialized successfully!"
echo "${INFO} Next: Install a CNI plugin using './scripts/06-install-cni.sh'"
echo "=============================================================================="
