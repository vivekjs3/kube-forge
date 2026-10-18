#!/usr/bin/env bash
# ==============================================================================
# 02-system-config.sh — Configure Linux kernel modules and sysctl for K3s
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (k3s) :: Step 02 - Kernel & Sysctl Configuration"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Kernel Modules
echo "${INFO} Configuring kernel modules in /etc/modules-load.d/k3s.conf..."
cat <<EOF > /etc/modules-load.d/k3s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
echo "${SUCCESS} Kernel modules 'overlay' and 'br_netfilter' loaded."

# 2. Sysctl Forwarding
echo "${INFO} Configuring network forwarding sysctls in /etc/sysctl.d/k3s.conf..."
cat <<EOF > /etc/sysctl.d/k3s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system > /dev/null
echo "${SUCCESS} Sysctl net.ipv4.ip_forward=1 configured."

echo "=============================================================================="
echo "${SUCCESS} Step 02 System Configuration Completed!"
echo "=============================================================================="
