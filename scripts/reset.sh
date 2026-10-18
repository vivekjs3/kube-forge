#!/usr/bin/env bash
# ==============================================================================
# reset.sh — Safely stop manual services and reset node
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

FORCE="${1:-}"

echo "=============================================================================="
echo " kube-forge (hardway) :: Teardown & Reset"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

if [[ "${FORCE}" != "--force" && "${FORCE}" != "-f" ]]; then
    echo ""
    echo "${WARN} WARNING: This operation will:"
    echo "  - Stop and disable all native Kubernetes systemd services"
    echo "  - Delete etcd state database in /var/lib/etcd"
    echo "  - Delete PKI certificates and generated kubeconfigs"
    echo ""
    read -rp "Are you sure you want to reset this node? [y/N]: " CONFIRM
    if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
        echo "${INFO} Reset aborted."
        exit 0
    fi
fi

# 1. Stop and disable services
echo "${INFO} Stopping services..."
SERVICES=(kube-apiserver kube-controller-manager kube-scheduler etcd kubelet kube-proxy containerd)
for svc in "${SERVICES[@]}"; do
    systemctl stop "${svc}" 2>/dev/null || true
    systemctl disable "${svc}" 2>/dev/null || true
done

# 2. Remove service units
echo "${INFO} Removing systemd units..."
rm -f /etc/systemd/system/kube-*.service
rm -f /etc/systemd/system/etcd.service
systemctl daemon-reload

# 3. Clean directories
echo "${INFO} Removing data and configuration directories..."
rm -rf /etc/etcd /var/lib/etcd
rm -rf /var/lib/kubernetes /var/lib/kubelet /var/lib/kube-proxy
rm -rf /etc/cni/net.d /var/lib/cni
rm -rf tls/ kubeconfigs/
rm -rf "$HOME/.kube"

# 4. Flush iptables
echo "${INFO} Flushing iptables..."
iptables -F || true
iptables -t nat -F || true
iptables -t mangle -F || true
iptables -X || true

echo "=============================================================================="
echo "${SUCCESS} Kubernetes The Hard Way node cleanly reset!"
echo "=============================================================================="
