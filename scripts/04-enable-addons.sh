#!/usr/bin/env bash
# ==============================================================================
# 04-enable-addons.sh — Enable Ingress Controller and Metrics Server Addons
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (minikube) :: Step 04 - Enable Cluster Addons"
echo "=============================================================================="

if ! command -v minikube &>/dev/null; then
    echo "${ERROR} minikube CLI not found." >&2
    exit 1
fi

echo "${INFO} Enabling ingress addon..."
minikube addons enable ingress

echo "${INFO} Enabling metrics-server addon..."
minikube addons enable metrics-server

echo ""
echo "${INFO} Currently enabled Minikube addons:"
minikube addons list | grep enabled

echo "=============================================================================="
echo "${SUCCESS} Step 04 Addons Enabled Successfully!"
echo "=============================================================================="
