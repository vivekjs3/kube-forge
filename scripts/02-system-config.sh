#!/usr/bin/env bash
# ==============================================================================
# 02-system-config.sh — Configure Kernel modules, sysctl, and disable swap
# Target: Ubuntu 22.04 / 24.04 LTS
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (kubeadm) :: Step 02 - Linux System & Kernel Configuration"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Disable Swap (Required for Kubernetes QoS & kubelet memory limits)
echo "${INFO} Checking swap status..."
if [[ $(swapon --show | wc -l) -gt 0 ]]; then
    echo "${INFO} Disabling active swap devices..."
    swapoff -a
    echo "${SUCCESS} Active swap disabled."
else
    echo "${SUCCESS} Swap is already inactive."
fi

# Make swap disable persistent across reboots
if grep -qE '^[^#].*\sswap\s' /etc/fstab; then
    echo "${INFO} Backing up /etc/fstab to /etc/fstab.bak.$(date +%F)..."
    cp /etc/fstab "/etc/fstab.bak.$(date +%F)"
    echo "${INFO} Commenting out swap entries in /etc/fstab..."
    sed -i.bak -r 's/(^.*swap.*$)/# \1/' /etc/fstab
    echo "${SUCCESS} Swap disabled persistently in /etc/fstab."
else
    echo "${SUCCESS} /etc/fstab has no active swap partitions."
fi

# 2. Configure Kernel Modules
MODULES_CONF="/etc/modules-load.d/k8s.conf"
echo "${INFO} Configuring kernel modules in ${MODULES_CONF}..."

cat <<EOF > "${MODULES_CONF}"
overlay
br_netfilter
EOF

echo "${INFO} Loading kernel modules into running kernel..."
modprobe overlay
modprobe br_netfilter

# Verify modules are loaded
for mod in overlay br_netfilter; do
    if lsmod | grep -q "^${mod}"; then
        echo "${SUCCESS} Kernel module '${mod}' loaded successfully."
    else
        echo "${ERROR} Failed to load kernel module '${mod}'." >&2
        exit 1
    fi
done

# 3. Configure Sysctl Network & Bridge Parameters
SYSCTL_CONF="/etc/sysctl.d/k8s.conf"
echo "${INFO} Configuring network bridge and forwarding sysctls in ${SYSCTL_CONF}..."

cat <<EOF > "${SYSCTL_CONF}"
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

echo "${INFO} Applying sysctl parameters..."
sysctl --system > /dev/null

# Verify sysctl values
IP_FWD=$(sysctl -n net.ipv4.ip_forward)
BR_IPT=$(sysctl -n net.bridge.bridge-nf-call-iptables)

if [[ "${IP_FWD}" -eq 1 && "${BR_IPT}" -eq 1 ]]; then
    echo "${SUCCESS} Kernel sysctl settings verified: net.ipv4.ip_forward=1, bridge-nf-call-iptables=1."
else
    echo "${ERROR} Sysctl verification failed. Please review ${SYSCTL_CONF}." >&2
    exit 1
fi

echo "=============================================================================="
echo "${SUCCESS} Step 02 Linux System & Kernel Configuration Completed!"
echo "=============================================================================="
