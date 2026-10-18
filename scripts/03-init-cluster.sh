#!/usr/bin/env bash
# ==============================================================================
# 03-init-cluster.sh — Initialize MicroK8s and export kubeconfig
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (microk8s) :: Step 03 - Initialize Cluster & Export Kubeconfig"
echo "=============================================================================="

echo "${INFO} Waiting for MicroK8s cluster to report ready state..."
microk8s status --wait-ready

echo "${INFO} Exporting kubeconfig to $HOME/.kube/config..."
mkdir -p "$HOME/.kube"
microk8s config > "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"

echo "${SUCCESS} MicroK8s node status:"
microk8s kubectl get nodes -o wide

echo "=============================================================================="
echo "${SUCCESS} Step 03 Cluster Initialized!"
echo "=============================================================================="
