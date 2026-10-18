#!/usr/bin/env bash
# ==============================================================================
# 02-install-minikube.sh — Download and install Minikube & kubectl CLIs
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
if [[ "${ARCH}" == "x86_64" ]]; then ARCH="amd64"; fi

echo "=============================================================================="
echo " kube-forge (minikube) :: Step 02 - Install Minikube & kubectl Binaries"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Download & Install Minikube
if ! command -v minikube &>/dev/null; then
    echo "${INFO} Downloading Minikube binary for ${ARCH}..."
    curl -s -Lo /usr/local/bin/minikube "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${ARCH}"
    chmod +x /usr/local/bin/minikube
fi
echo "${SUCCESS} Minikube installed: $(minikube version --short)"

# 2. Download & Install kubectl
if ! command -v kubectl &>/dev/null; then
    echo "${INFO} Downloading kubectl..."
    curl -s -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
    chmod +x /usr/local/bin/kubectl
fi
echo "${SUCCESS} kubectl verified: $(kubectl version --client -o yaml | grep gitVersion | head -n 1)"

echo "=============================================================================="
echo "${SUCCESS} Step 02 Minikube & kubectl Installation Completed!"
echo "=============================================================================="
