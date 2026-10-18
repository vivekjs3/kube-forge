#!/usr/bin/env bash
# ==============================================================================
# 03-container-runtime.sh — Install & configure containerd with systemd cgroups
# Target: Ubuntu 22.04 / 24.04 LTS
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (kubeadm) :: Step 03 - Container Runtime (containerd) Setup"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

# 1. Install containerd packages
echo "${INFO} Checking if containerd is already installed..."
if ! command -v containerd &>/dev/null; then
    echo "${INFO} Setting up Docker repository for official containerd.io packages..."
    install -m 0755 -d /etc/apt/keyrings
    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    . /etc/os-release
    UBUNTU_CODENAME="${VERSION_CODENAME:-noble}"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
        > /etc/apt/sources.list.d/docker.list

    apt-get update -y
    apt-get install -y containerd.io
    echo "${SUCCESS} containerd.io package installed."
else
    echo "${SUCCESS} containerd is already installed."
fi

# 2. Configure containerd with SystemdCgroup = true
echo "${INFO} Configuring /etc/containerd/config.toml..."
mkdir -p /etc/containerd

if [[ -f /etc/containerd/config.toml ]]; then
    cp /etc/containerd/config.toml "/etc/containerd/config.toml.bak.$(date +%F_%H%M%S)"
fi

# Generate default configuration
containerd config default > /etc/containerd/config.toml

# Enable SystemdCgroup driver for runc (Crucial for Kubernetes!)
echo "${INFO} Enabling SystemdCgroup driver in containerd config..."
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Ensure correct sandbox/pause image is configured
sed -i 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.10"|g' /etc/containerd/config.toml

# 3. Restart and Enable Service
echo "${INFO} Restarting containerd daemon..."
systemctl daemon-reload
systemctl restart containerd
systemctl enable containerd

# 4. Verify containerd is operational
if systemctl is-active --quiet containerd; then
    echo "${SUCCESS} containerd is active and running."
else
    echo "${ERROR} containerd failed to start. Check 'systemctl status containerd'." >&2
    exit 1
fi

if [[ -S /run/containerd/containerd.sock ]]; then
    echo "${SUCCESS} containerd gRPC socket active at /run/containerd/containerd.sock."
else
    echo "${ERROR} containerd socket not found at /run/containerd/containerd.sock." >&2
    exit 1
fi

echo "=============================================================================="
echo "${SUCCESS} Step 03 Container Runtime Setup Completed Successfully!"
echo "=============================================================================="
