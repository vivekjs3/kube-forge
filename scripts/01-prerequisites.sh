#!/usr/bin/env bash
# ==============================================================================
# 01-prerequisites.sh — Verify system and install PKI tools (cfssl, cfssljson)
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (hardway) :: Step 01 - Prerequisites & PKI Tooling Setup"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Base tools
PKGS=(curl wget tar iproute2 iptables socat conntrack)
MISSING=()
for pkg in "${PKGS[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
        MISSING+=("$pkg")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "${INFO} Installing base packages: ${MISSING[*]}..."
    apt-get update -y && apt-get install -y "${MISSING[@]}"
fi
echo "${SUCCESS} Base packages verified."

# 2. Install cfssl and cfssljson
echo "${INFO} Checking cfssl and cfssljson..."
CFSSL_VER="v1.6.5"
ARCH=$(dpkg --print-architecture)

if ! command -v cfssl &>/dev/null; then
    echo "${INFO} Downloading cfssl ${CFSSL_VER}..."
    curl -s -L -o /usr/local/bin/cfssl "https://github.com/cloudflare/cfssl/releases/download/${CFSSL_VER}/cfssl_1.6.5_linux_${ARCH}"
    chmod +x /usr/local/bin/cfssl
fi

if ! command -v cfssljson &>/dev/null; then
    echo "${INFO} Downloading cfssljson ${CFSSL_VER}..."
    curl -s -L -o /usr/local/bin/cfssljson "https://github.com/cloudflare/cfssl/releases/download/${CFSSL_VER}/cfssljson_1.6.5_linux_${ARCH}"
    chmod +x /usr/local/bin/cfssljson
fi

echo "${SUCCESS} cfssl version: $(cfssl version | head -n 1)"
echo "=============================================================================="
echo "${SUCCESS} Step 01 Prerequisites Completed!"
echo "=============================================================================="
