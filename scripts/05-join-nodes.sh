#!/usr/bin/env bash
# ==============================================================================
# 05-join-nodes.sh — MicroK8s Multi-Node Clustering & Join Tokens
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

JOIN_STR="${1:-}"

echo "=============================================================================="
echo " kube-forge (microk8s) :: Step 05 - Node Clustering"
echo "=============================================================================="

# Case 1: Run on worker node with join connection string
if [[ -n "${JOIN_STR}" ]]; then
    echo "${INFO} Joining cluster using provided connection string..."
    microk8s join "${JOIN_STR}"
    echo "${SUCCESS} Node joined successfully!"
    exit 0
fi

# Case 2: Run on control plane to generate token
echo "${INFO} Generating cluster join token on control plane..."
microk8s add-node

echo ""
echo "=============================================================================="
echo "${INFO} Run the outputted 'microk8s join ...' command on your worker node."
echo "=============================================================================="
