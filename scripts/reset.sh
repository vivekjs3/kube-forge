#!/usr/bin/env bash
# ==============================================================================
# reset.sh — Safely teardown and uninstall K3s
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

FORCE="${1:-}"

echo "=============================================================================="
echo " kube-forge (k3s) :: Teardown & Uninstall"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

if [[ "${FORCE}" != "--force" && "${FORCE}" != "-f" ]]; then
    echo ""
    echo "${WARN} WARNING: This operation will permanently delete:"
    echo "  - Local SQLite / etcd state database"
    echo "  - All persistent storage volumes in /var/lib/rancher/k3s/storage/"
    echo "  - All running containers and network interfaces"
    echo ""
    read -rp "Are you sure you want to uninstall K3s from this node? [y/N]: " CONFIRM
    if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
        echo "${INFO} Uninstall aborted."
        exit 0
    fi
fi

# 1. Run official uninstall script if available
if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
    echo "${INFO} Running /usr/local/bin/k3s-uninstall.sh..."
    /usr/local/bin/k3s-uninstall.sh || true
elif [[ -f /usr/local/bin/k3s-agent-uninstall.sh ]]; then
    echo "${INFO} Running /usr/local/bin/k3s-agent-uninstall.sh..."
    /usr/local/bin/k3s-agent-uninstall.sh || true
else
    echo "${INFO} Built-in uninstall script not found. Proceeding with manual cleanup..."
    systemctl stop k3s 2>/dev/null || true
    systemctl stop k3s-agent 2>/dev/null || true
fi

# 2. Cleanup state directories
echo "${INFO} Removing K3s state directories..."
rm -rf /etc/rancher/k3s
rm -rf /var/lib/rancher/k3s
rm -rf /run/k3s
rm -rf /var/lib/kubelet
rm -rf "$HOME/.kube"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "${TARGET_USER}" | cut -d: -f6 2>/dev/null || echo "$HOME")
rm -rf "${TARGET_HOME}/.kube"

# 3. Flush iptables
echo "${INFO} Flushing iptables..."
iptables -F || true
iptables -t nat -F || true
iptables -t mangle -F || true
iptables -X || true

echo "=============================================================================="
echo "${SUCCESS} K3s uninstalled and node reset cleanly!"
echo "=============================================================================="
