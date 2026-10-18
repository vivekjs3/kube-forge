#!/usr/bin/env bash
# ==============================================================================
# reset.sh — Safely teardown and uninstall RKE2
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

FORCE="${1:-}"

echo "=============================================================================="
echo " kube-forge (rke2) :: Teardown & Uninstall"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

if [[ "${FORCE}" != "--force" && "${FORCE}" != "-f" ]]; then
    echo ""
    echo "${WARN} WARNING: This operation will permanently delete:"
    echo "  - Local etcd database and state"
    echo "  - PKI certificates and cluster tokens"
    echo "  - All persistent storage volumes"
    echo ""
    read -rp "Are you sure you want to uninstall RKE2 from this node? [y/N]: " CONFIRM
    if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
        echo "${INFO} Uninstall aborted."
        exit 0
    fi
fi

# 1. Official uninstaller
if [[ -f /usr/local/bin/rke2-uninstall.sh ]]; then
    echo "${INFO} Running /usr/local/bin/rke2-uninstall.sh..."
    /usr/local/bin/rke2-uninstall.sh || true
elif [[ -f /usr/local/bin/rke2-agent-uninstall.sh ]]; then
    echo "${INFO} Running /usr/local/bin/rke2-agent-uninstall.sh..."
    /usr/local/bin/rke2-agent-uninstall.sh || true
else
    echo "${INFO} Built-in uninstall script not found. Proceeding with manual teardown..."
    systemctl stop rke2-server 2>/dev/null || true
    systemctl stop rke2-agent 2>/dev/null || true
fi

# 2. Cleanup mounts
grep -E '/var/lib/rancher/rke2' /proc/mounts | cut -d' ' -f2 | sort -r | xargs -r -t -m umount 2>/dev/null || true

# 3. Cleanup directories
echo "${INFO} Removing state directories..."
rm -rf /etc/rancher/rke2
rm -rf /var/lib/rancher/rke2
rm -rf /run/k3s
rm -rf /var/lib/kubelet
rm -rf "$HOME/.kube"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "${TARGET_USER}" | cut -d: -f6 2>/dev/null || echo "$HOME")
rm -rf "${TARGET_HOME}/.kube"

# 4. Flush iptables
echo "${INFO} Flushing iptables..."
iptables -F || true
iptables -t nat -F || true
iptables -t mangle -F || true
iptables -X || true

echo "=============================================================================="
echo "${SUCCESS} RKE2 uninstalled and node reset cleanly!"
echo "=============================================================================="
