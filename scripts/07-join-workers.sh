#!/usr/bin/env bash
# ==============================================================================
# 07-join-workers.sh — Generate join token or join a worker node
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (kubeadm) :: Step 07 - Worker Node Joining"
echo "=============================================================================="

# Case 1: Run on Control Plane (Generates join command)
if [[ -f /etc/kubernetes/admin.conf ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo "${ERROR} Please run as root or with sudo to generate tokens." >&2
        exit 1
    fi
    echo "${INFO} Control plane detected. Generating fresh bootstrap token and join command..."
    JOIN_CMD=$(kubeadm token create --print-join-command)
    
    echo ""
    echo "=============================================================================="
    echo " RUN THIS COMMAND ON EACH WORKER NODE WITH SUDO:"
    echo "=============================================================================="
    echo ""
    echo "sudo ${JOIN_CMD}"
    echo ""
    echo "=============================================================================="
    echo "${INFO} Note: This bootstrap token is valid for 24 hours."
    exit 0
fi

# Case 2: Run on Worker Node
if [[ $# -eq 0 ]]; then
    echo "${INFO} This script can be run on:"
    echo "  1. The Control Plane node (to print the join command)"
    echo "  2. The Worker node passing the join arguments:"
    echo "     sudo ./scripts/07-join-workers.sh <apiserver-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root on the worker node." >&2
    exit 1
fi

echo "${INFO} Joining worker node to cluster with provided arguments..."
kubeadm join "$@"

echo "=============================================================================="
echo "${SUCCESS} Worker node joined! Verify on control plane with: 'kubectl get nodes'"
echo "=============================================================================="
