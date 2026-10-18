#!/usr/bin/env bash
# ==============================================================================
# 01-prerequisites.sh — Verify system and hardware requirements for K3s
# Target: Ubuntu 22.04 / 24.04 LTS (Debian/Raspberry Pi OS compatible)
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (k3s) :: Step 01 - Prerequisites Verification"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. OS check
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "${INFO} Detected Operating System: ${NAME} ${VERSION_ID:-}"
fi

# 2. Memory Check (K3s needs minimum 512MB RAM)
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
echo "${INFO} Total RAM: ${TOTAL_MEM_MB} MB"

if [[ ${TOTAL_MEM_MB} -lt 480 ]]; then
    echo "${ERROR} K3s requires at least 512 MB of RAM. Found ${TOTAL_MEM_MB} MB." >&2
    exit 1
fi
echo "${SUCCESS} RAM requirement satisfied (>= 512 MB)."

# 3. CPU Check (1 vCPU minimum)
CPUS=$(nproc)
echo "${INFO} CPU Cores: ${CPUS}"
echo "${SUCCESS} CPU requirement satisfied."

# 4. Utilities
PKGS=(curl iptables iproute2)
for pkg in "${PKGS[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
        echo "${INFO} Installing required tool: $pkg..."
        apt-get update -y && apt-get install -y "$pkg"
    fi
done
echo "${SUCCESS} Essential utilities verified."

echo "=============================================================================="
echo "${SUCCESS} Step 01 Prerequisites Verification Completed!"
echo "=============================================================================="
