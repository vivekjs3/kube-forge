#!/usr/bin/env bash
# ==============================================================================
# 03-create-cluster.sh — Start local Minikube cluster
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

DRIVER="${1:-docker}"
CPUS="${MINIKUBE_CPUS:-2}"
MEMORY="${MINIKUBE_MEMORY:-2048}"

echo "=============================================================================="
echo " kube-forge (minikube) :: Step 03 - Cluster Creation (Driver: ${DRIVER})"
echo "=============================================================================="

if ! command -v minikube &>/dev/null; then
    echo "${ERROR} minikube CLI not found. Run '02-install-minikube.sh' first." >&2
    exit 1
fi

echo "${INFO} Launching Minikube cluster with ${CPUS} CPUs and ${MEMORY} MB RAM..."
minikube start \
    --driver="${DRIVER}" \
    --cpus="${CPUS}" \
    --memory="${MEMORY}" \
    --kubernetes-version="v1.31.0"

echo "${INFO} Minikube cluster status:"
minikube status

echo "=============================================================================="
echo "${SUCCESS} Minikube cluster is active and configured in ~/.kube/config!"
echo "=============================================================================="
