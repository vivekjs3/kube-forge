#!/usr/bin/env bash
# ==============================================================================
# 02-generate-configs.sh — Generate declarative machine configs & talosconfig
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

CLUSTER_NAME="${1:-kube-forge-talos}"
ENDPOINT_IP="${2:-10.10.10.10}"
OUTPUT_DIR="generated"

echo "=============================================================================="
echo " kube-forge (talos) :: Step 02 - Generate Machine Configurations"
echo "=============================================================================="

mkdir -p "${OUTPUT_DIR}"

echo "${INFO} Generating Talos machine configs for cluster '${CLUSTER_NAME}'..."
echo "${INFO} Control plane endpoint: https://${ENDPOINT_IP}:6443"

talosctl gen config "${CLUSTER_NAME}" "https://${ENDPOINT_IP}:6443" \
    --output-dir "${OUTPUT_DIR}" \
    --with-docs=false \
    --with-examples=false

# Configure local talosctl client
echo "${INFO} Configuring talosconfig endpoints..."
talosctl --talosconfig="${OUTPUT_DIR}/talosconfig" config endpoint "${ENDPOINT_IP}"
talosctl --talosconfig="${OUTPUT_DIR}/talosconfig" config node "${ENDPOINT_IP}"

echo "=============================================================================="
echo "${SUCCESS} Configs generated in ./${OUTPUT_DIR}/:"
echo "  - ${OUTPUT_DIR}/controlplane.yaml"
echo "  - ${OUTPUT_DIR}/worker.yaml"
echo "  - ${OUTPUT_DIR}/talosconfig"
echo "=============================================================================="
