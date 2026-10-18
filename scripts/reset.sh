#!/usr/bin/env bash
# ==============================================================================
# reset.sh — Safely teardown and reset Kubernetes node state
# Target: Ubuntu 22.04 / 24.04 LTS
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

FORCE="${1:-}"

echo "=============================================================================="
echo " kube-forge (kubeadm) :: Node Teardown & Cluster Reset"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# Confirmation Prompt
if [[ "${FORCE}" != "--force" && "${FORCE}" != "-f" ]]; then
    echo ""
    echo "${WARN} WARNING: This operation will permanently delete:"
    echo "  - Local etcd database and snapshots"
    echo "  - Control plane and worker certificates"
    echo "  - Running container sandboxes and volumes"
    echo "  - Host iptables rules and CNI network bridges"
    echo ""
    read -rp "Are you sure you wish to reset this node? [y/N]: " CONFIRM
    if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
        echo "${INFO} Reset aborted by user."
        exit 0
    fi
fi

# 1. Execute kubeadm reset
if command -v kubeadm &>/dev/null; then
    echo "${INFO} Running 'kubeadm reset -f'..."
    kubeadm reset -f --cri-socket="unix:///run/containerd/containerd.sock" || true
else
    echo "${INFO} kubeadm command not found. Proceeding with manual cleanup..."
fi

# 2. Flush Netfilter & IPVS Rules
echo "${INFO} Flushing iptables and IPVS rules..."
iptables -F || true
iptables -t nat -F || true
iptables -t mangle -F || true
iptables -t raw -F || true
iptables -X || true

if command -v ipvsadm &>/dev/null; then
    ipvsadm --clear || true
fi

# 3. Clean up virtual network devices
echo "${INFO} Deleting virtual CNI interfaces..."
for dev in cni0 flannel.1 vxlan.calico cali+; do
    ip link delete "${dev}" 2>/dev/null || true
done

# 4. Clean up directories and state files
echo "${INFO} Cleaning state directories..."
rm -rf /etc/kubernetes/
rm -rf /var/lib/etcd/
rm -rf /var/lib/kubelet/
rm -rf /var/run/kubernetes/
rm -rf /etc/cni/net.d/
rm -rf /var/lib/cni/

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "${TARGET_USER}" | cut -d: -f6 2>/dev/null || echo "$HOME")
rm -rf "${TARGET_HOME}/.kube"
rm -rf "$HOME/.kube"

# 5. Restart Container Runtime
echo "${INFO} Restarting containerd to purge orphan container sandboxes..."
if systemctl is-active --quiet containerd; then
    systemctl restart containerd
fi

echo "=============================================================================="
echo "${SUCCESS} Node successfully reset to pristine state!"
echo "=============================================================================="
