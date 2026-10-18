#!/usr/bin/env bash
# ==============================================================================
# 04-enable-addons.sh — Enable DNS, Ingress, and Storage Addons in MicroK8s
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (microk8s) :: Step 04 - Enable MicroK8s Addons"
echo "=============================================================================="

echo "${INFO} Enabling CoreDNS addon..."
microk8s enable dns

echo "${INFO} Enabling Ingress Controller addon..."
microk8s enable ingress

echo "${INFO} Enabling Hostpath Dynamic Storage addon..."
microk8s enable hostpath-storage

echo ""
echo "${INFO} Checking active addons:"
microk8s status | grep -A 10 "enabled:"

echo "=============================================================================="
echo "${SUCCESS} Step 04 Addons Enabled Successfully!"
echo "=============================================================================="
