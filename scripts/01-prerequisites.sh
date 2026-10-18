#!/usr/bin/env bash
# ==============================================================================
# 01-prerequisites.sh — Setup Python3, virtual environment, and Ansible
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (kubespray) :: Step 01 - Ansible Controller Setup"
echo "=============================================================================="

# 1. Install system Python packages
PKGS=(python3 python3-pip python3-venv git curl)
for pkg in "${PKGS[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null 2>&1; then
        echo "${INFO} Installing system package: $pkg..."
        sudo apt-get update -y && sudo apt-get install -y "$pkg"
    fi
done
echo "${SUCCESS} System Python & Git verified."

# 2. Setup Virtualenv
VENV_DIR="venv"
if [[ ! -d "${VENV_DIR}" ]]; then
    echo "${INFO} Creating Python virtual environment in ./${VENV_DIR}..."
    python3 -m venv "${VENV_DIR}"
fi

# 3. Activate and install Ansible & requirements
echo "${INFO} Activating virtualenv and installing Ansible dependencies..."
# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

pip install --upgrade pip setuptools wheel
pip install ansible-core cryptography netaddr pbr jmespath

echo "${SUCCESS} Ansible installed: $(ansible --version | head -n 1)"
echo "=============================================================================="
echo "${SUCCESS} Step 01 Controller Setup Completed!"
echo "=============================================================================="
