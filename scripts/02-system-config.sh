#!/usr/bin/env bash
# ==============================================================================
# 02-system-config.sh — Configure Linux kernel modules and sysctl
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (hardway) :: Step 02 - Kernel & Sysctl Configuration"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Disable Swap
swapoff -a || true
sed -i.bak -r 's/(^.*swap.*$)/# \1/' /etc/fstab || true
echo "${SUCCESS} Swap disabled."

# 2. Kernel Modules
cat <<EOF > /etc/modules-load.d/kubernetes.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
echo "${SUCCESS} Kernel modules loaded."

# 3. Sysctl
cat <<EOF > /etc/sysctl.d/99-kubernetes.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system > /dev/null
echo "${SUCCESS} Sysctl parameters applied."

echo "=============================================================================="
echo "${SUCCESS} Step 02 System Configuration Completed!"
echo "=============================================================================="
