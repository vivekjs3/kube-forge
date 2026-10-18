#!/usr/bin/env bash
# ==============================================================================
# 04-install-kubernetes.sh — Install kubeadm, kubelet, and kubectl (v1.31)
# Target: Ubuntu 22.04 / 24.04 LTS
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

K8S_VERSION="${K8S_VERSION:-v1.31}"

echo "=============================================================================="
echo " kube-forge (kubeadm) :: Step 04 - Install Kubernetes Binaries (${K8S_VERSION})"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Setup official Kubernetes community apt repository (pkgs.k8s.io)
echo "${INFO} Adding official Kubernetes apt repository for ${K8S_VERSION}..."
mkdir -p -m 755 /etc/apt/keyrings

KEYRING_FILE="/etc/apt/keyrings/kubernetes-apt-keyring.gpg"
if [[ -f "${KEYRING_FILE}" ]]; then
    rm -f "${KEYRING_FILE}"
fi

curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" | gpg --dearmor -o "${KEYRING_FILE}"
chmod 644 "${KEYRING_FILE}"

echo "deb [signed-by=${KEYRING_FILE}] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list

# 2. Install Packages
echo "${INFO} Updating package index and installing kubelet, kubeadm, kubectl..."
apt-get update -y
apt-get install -y kubelet kubeadm kubectl

# 3. Pin Package Versions to Prevent Automatic Upgrades
echo "${INFO} Pinning package versions with apt-mark hold..."
apt-mark hold kubelet kubeadm kubectl

# 4. Enable Kubelet Service
echo "${INFO} Enabling kubelet service (will start upon cluster init)..."
systemctl enable kubelet

# 5. Verify Binaries
echo "${INFO} Verifying installed binary versions:"
kubeadm version -o short
kubelet --version
kubectl version --client -o yaml | grep gitVersion

echo "=============================================================================="
echo "${SUCCESS} Step 04 Kubernetes Binaries (${K8S_VERSION}) Installed & Pinned!"
echo "=============================================================================="
