#!/usr/bin/env bash
# ==============================================================================
# 01-prerequisites.sh — Verify system and snapd prerequisites for MicroK8s
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (microk8s) :: Step 01 - Prerequisites Verification"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Check RAM
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
echo "${INFO} Total RAM: ${TOTAL_MEM_MB} MB"
if [[ ${TOTAL_MEM_MB} -lt 1800 ]]; then
    echo "${WARN} MicroK8s recommends at least 2 GB RAM."
else
    echo "${SUCCESS} RAM requirement satisfied."
fi

# 2. Check & Install snapd
if ! command -v snap &>/dev/null; then
    echo "${INFO} snapd not detected. Installing snapd..."
    apt-get update -y && apt-get install -y snapd iptables
fi
echo "${SUCCESS} snapd is available: $(snap --version | head -n 1)"

echo "=============================================================================="
echo "${SUCCESS} Step 01 Prerequisites Completed!"
echo "=============================================================================="
