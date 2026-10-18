#!/usr/bin/env bash
# ==============================================================================
# reset.sh — Safely teardown and remove MicroK8s snap
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

FORCE="${1:-}"

echo "=============================================================================="
echo " kube-forge (microk8s) :: Teardown & Purge"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

if [[ "${FORCE}" != "--force" && "${FORCE}" != "-f" ]]; then
    echo ""
    echo "${WARN} WARNING: This operation will permanently remove MicroK8s and all cluster state."
    read -rp "Are you sure you want to uninstall MicroK8s? [y/N]: " CONFIRM
    if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
        echo "${INFO} Removal aborted."
        exit 0
    fi
fi

if command -v microk8s &>/dev/null; then
    echo "${INFO} Stopping MicroK8s services..."
    microk8s stop 2>/dev/null || true
    echo "${INFO} Purging MicroK8s snap..."
    snap remove microk8s --purge || true
fi

echo "${INFO} Removing state directories..."
rm -rf /var/snap/microk8s
rm -rf "$HOME/.kube"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "${TARGET_USER}" | cut -d: -f6 2>/dev/null || echo "$HOME")
rm -rf "${TARGET_HOME}/.kube"

echo "=============================================================================="
echo "${SUCCESS} MicroK8s cleanly removed and node restored!"
echo "=============================================================================="
