#!/usr/bin/env bash
# ==============================================================================
# 01-prerequisites.sh — Verify hardware, OS, and software prerequisites
# Target: Ubuntu 22.04 / 24.04 LTS
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (kubeadm) :: Step 01 - Prerequisites Verification"
echo "=============================================================================="

# 1. Privilege Check
if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi
echo "${SUCCESS} Running with root privileges."

# 2. Operating System Validation
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "${INFO} Detected OS: ${NAME} ${VERSION_ID}"
    if [[ "${ID}" != "ubuntu" && "${ID_LIKE:-}" != *"ubuntu"* && "${ID}" != "debian" ]]; then
        echo "${WARN} This script is optimized for Ubuntu/Debian. Continuing with caution..."
    fi
else
    echo "${WARN} Cannot determine OS release. Proceeding cautiously."
fi

# 3. CPU Core Count Check
CPU_CORES=$(nproc)
echo "${INFO} CPU Cores detected: ${CPU_CORES}"
if [[ ${CPU_CORES} -lt 2 ]]; then
    echo "${ERROR} Kubernetes control plane requires at least 2 CPU cores. (Detected: ${CPU_CORES})" >&2
    echo "${WARN} Worker nodes can run on 1 CPU, but control plane initialization will fail."
else
    echo "${SUCCESS} CPU core requirement satisfied (>= 2)."
fi

# 4. Memory (RAM) Check
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
echo "${INFO} Total RAM detected: ${TOTAL_MEM_MB} MB"
if [[ ${TOTAL_MEM_MB} -lt 1800 ]]; then
    echo "${WARN} Detected less than 2 GB RAM (${TOTAL_MEM_MB} MB). Control plane may experience memory pressure."
else
    echo "${SUCCESS} Memory requirement satisfied (>= 2 GB)."
fi

# 5. Check Hardware UUID & MAC Address
PRODUCT_UUID=$(cat /sys/class/dmi/id/product_uuid 2>/dev/null || echo "unknown")
echo "${INFO} Machine Product UUID: ${PRODUCT_UUID}"

# 6. Basic Utility Dependencies
REQUIRED_PKGS=(curl apt-transport-https ca-certificates gnupg lsb-release iproute2 iptables)
MISSING_PKGS=()

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
    echo "${INFO} Installing required base utilities: ${MISSING_PKGS[*]}..."
    apt-get update -y
    apt-get install -y "${MISSING_PKGS[@]}"
    echo "${SUCCESS} Base utilities installed."
else
    echo "${SUCCESS} All base utilities are already present."
fi

echo "=============================================================================="
echo "${SUCCESS} Step 01 Prerequisites Verification Completed Successfully!"
echo "=============================================================================="
