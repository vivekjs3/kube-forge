#!/usr/bin/env bash
# ==============================================================================
# reset.sh — Remotely wipe and reset a Talos Linux node via gRPC API
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

NODE_IP="${1:-}"
FORCE="${2:-}"

echo "=============================================================================="
echo " kube-forge (talos) :: Node Teardown & Reset"
echo "=============================================================================="

if [[ -z "${NODE_IP}" ]]; then
    echo "${ERROR} Please specify the node IP to reset."
    echo "Usage: ./scripts/reset.sh <NODE_IP> [--force]"
    exit 1
fi

if [[ "${FORCE}" != "--force" && "${FORCE}" != "-f" ]]; then
    echo ""
    echo "${WARN} WARNING: This operation will:"
    echo "  - Completely wipe all disk partitions on node ${NODE_IP}"
    echo "  - Delete all local container data and etcd state"
    echo "  - Reboot the node into pristine maintenance mode"
    echo ""
    read -rp "Are you sure you want to reset node ${NODE_IP}? [y/N]: " CONFIRM
    if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
        echo "${INFO} Reset aborted."
        exit 0
    fi
fi

TALOSCONFIG="generated/talosconfig"
TALOS_ARGS=(--nodes "${NODE_IP}" --endpoints "${NODE_IP}" --graceful=false --reboot)

if [[ -f "${TALOSCONFIG}" ]]; then
    TALOS_ARGS+=(--talosconfig "${TALOSCONFIG}")
fi

echo "${INFO} Sending reset command to node ${NODE_IP}..."
talosctl reset "${TALOS_ARGS[@]}"

echo "=============================================================================="
echo "${SUCCESS} Reset signal accepted! Node ${NODE_IP} is wiping disks and rebooting."
echo "=============================================================================="
