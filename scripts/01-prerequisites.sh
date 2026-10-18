#!/usr/bin/env bash
# ==============================================================================
# 01-prerequisites.sh — Install talosctl and kubectl management tools
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
if [[ "${ARCH}" == "x86_64" ]]; then ARCH="amd64"; fi

echo "=============================================================================="
echo " kube-forge (talos) :: Step 01 - Install Management Tooling (talosctl)"
echo "=============================================================================="

# 1. Install talosctl
if ! command -v talosctl &>/dev/null; then
    echo "${INFO} Downloading talosctl CLI..."
    curl -sL https://talos.dev/install | sh
fi
echo "${SUCCESS} talosctl installed: $(talosctl version --client --short 2>/dev/null || talosctl version --client)"

# 2. Install kubectl
if ! command -v kubectl &>/dev/null; then
    echo "${INFO} Downloading kubectl CLI..."
    sudo curl -s -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
    sudo chmod +x /usr/local/bin/kubectl
fi
echo "${SUCCESS} kubectl verified."

echo "=============================================================================="
echo "${SUCCESS} Step 01 Management Tooling Verified!"
echo "=============================================================================="
