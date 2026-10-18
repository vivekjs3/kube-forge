#!/usr/bin/env bash
# ==============================================================================
# 01-prerequisites.sh — Verify system and hardware requirements for RKE2
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (rke2) :: Step 01 - Prerequisites Verification"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Memory Check (RKE2 Server requires minimum 3.5GB RAM for etcd and control plane)
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
echo "${INFO} Total RAM detected: ${TOTAL_MEM_MB} MB"

if [[ ${TOTAL_MEM_MB} -lt 3000 ]]; then
    echo "${WARN} Detected less than 3 GB RAM (${TOTAL_MEM_MB} MB). RKE2 Server may experience high memory pressure."
else
    echo "${SUCCESS} RAM requirement satisfied."
fi

# 2. CPU Check
CPUS=$(nproc)
echo "${INFO} CPU Cores: ${CPUS}"
if [[ ${CPUS} -lt 2 ]]; then
    echo "${WARN} RKE2 Server recommends at least 2 vCPUs."
else
    echo "${SUCCESS} CPU requirement satisfied (>= 2)."
fi

# 3. Utilities
PKGS=(curl iptables iproute2 tar)
for pkg in "${PKGS[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
        echo "${INFO} Installing utility: $pkg..."
        apt-get update -y && apt-get install -y "$pkg"
    fi
done
echo "${SUCCESS} Base system utilities verified."

echo "=============================================================================="
echo "${SUCCESS} Step 01 Prerequisites Verification Completed!"
echo "=============================================================================="
