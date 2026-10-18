#!/usr/bin/env bash
# ==============================================================================
# 02-system-config.sh — Configure Linux kernel modules and sysctl for RKE2
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (rke2) :: Step 02 - Kernel & Sysctl Configuration"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Modules
echo "${INFO} Configuring kernel modules in /etc/modules-load.d/rke2.conf..."
cat <<EOF > /etc/modules-load.d/rke2.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
echo "${SUCCESS} Modules loaded."

# 2. Sysctl
echo "${INFO} Configuring network forwarding sysctls in /etc/sysctl.d/rke2.conf..."
cat <<EOF > /etc/sysctl.d/rke2.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system > /dev/null
echo "${SUCCESS} Sysctl parameters applied."

echo "=============================================================================="
echo "${SUCCESS} Step 02 System Configuration Completed!"
echo "=============================================================================="
