#!/usr/bin/env bash
# ==============================================================================
# reset.sh — Safely delete Minikube cluster and purge local caches
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

FORCE="${1:-}"

echo "=============================================================================="
echo " kube-forge (minikube) :: Cluster Deletion & Purge"
echo "=============================================================================="

if [[ "${FORCE}" != "--force" && "${FORCE}" != "-f" ]]; then
    echo ""
    echo "${WARN} WARNING: This operation will permanently delete your local Minikube cluster and profile."
    read -rp "Are you sure you want to delete this Minikube cluster? [y/N]: " CONFIRM
    if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
        echo "${INFO} Deletion aborted."
        exit 0
    fi
fi

if command -v minikube &>/dev/null; then
    echo "${INFO} Deleting Minikube cluster instances..."
    minikube delete --all --purge || true
fi

echo "${INFO} Cleaning up ~/.minikube directory..."
rm -rf "$HOME/.minikube"

echo "=============================================================================="
echo "${SUCCESS} Minikube cluster deleted and environment purged cleanly!"
echo "=============================================================================="
