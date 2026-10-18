#!/usr/bin/env bash
# ==============================================================================
# 02-install-snap.sh — Install MicroK8s snap package and configure group
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

CHANNEL="${MICROK8S_CHANNEL:-1.31/stable}"

echo "=============================================================================="
echo " kube-forge (microk8s) :: Step 02 - Install MicroK8s Snap (${CHANNEL})"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Install Snap
echo "${INFO} Installing MicroK8s snap from channel ${CHANNEL}..."
snap install microk8s --classic --channel="${CHANNEL}"

# 2. Add user to microk8s group
TARGET_USER="${SUDO_USER:-$USER}"
echo "${INFO} Adding user '${TARGET_USER}' to group 'microk8s'..."
usermod -aG microk8s "${TARGET_USER}"

TARGET_HOME=$(getent passwd "${TARGET_USER}" | cut -d: -f6 2>/dev/null || echo "$HOME")
mkdir -p "${TARGET_HOME}/.kube"
chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.kube"

# 3. Add alias for kubectl
snap alias microk8s.kubectl kubectl || true

echo "=============================================================================="
echo "${SUCCESS} MicroK8s installed! User '${TARGET_USER}' added to 'microk8s' group."
echo "=============================================================================="
