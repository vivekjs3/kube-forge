#!/usr/bin/env bash
# ==============================================================================
# 01-prerequisites.sh — Verify virtualization, Docker, and workstation resources
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (minikube) :: Step 01 - Workstation Prerequisites"
echo "=============================================================================="

# 1. Memory Check
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_MB=$((TOTAL_MEM_KB / 1024))
echo "${INFO} Total RAM detected: ${TOTAL_MEM_MB} MB"

if [[ ${TOTAL_MEM_MB} -lt 2000 ]]; then
    echo "${WARN} Minikube recommends at least 2 GB of RAM."
else
    echo "${SUCCESS} RAM requirement satisfied (>= 2 GB)."
fi

# 2. CPU Cores Check
CPUS=$(nproc)
echo "${INFO} CPU Cores: ${CPUS}"
if [[ ${CPUS} -lt 2 ]]; then
    echo "${WARN} Minikube recommends at least 2 CPU cores."
else
    echo "${SUCCESS} CPU cores requirement satisfied (>= 2)."
fi

# 3. Check Docker Engine
if command -v docker &>/dev/null; then
    echo "${SUCCESS} Docker engine is installed: $(docker --version)"
    if docker info &>/dev/null; then
        echo "${SUCCESS} Docker daemon is accessible."
    else
        echo "${WARN} Cannot connect to Docker daemon. User might need to be added to docker group: 'sudo usermod -aG docker \$USER'."
    fi
else
    echo "${INFO} Docker not found. You can install Docker or use KVM2/Podman drivers."
fi

# 4. Check Virtualization Support (VT-x / AMD-v)
if grep -q -E 'vmx|svm' /proc/cpuinfo; then
    echo "${SUCCESS} Hardware virtualization extensions (VT-x/AMD-v) detected."
else
    echo "${WARN} Hardware virtualization not detected. Docker container driver will still function."
fi

echo "=============================================================================="
echo "${SUCCESS} Step 01 Prerequisites Verification Completed!"
echo "=============================================================================="
