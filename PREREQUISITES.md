# Minikube Prerequisites & System Requirements

Before starting Minikube, verify that your workstation meets the following prerequisites.

---

## 1. Hardware Minimum Requirements

- **CPU:** 2 or more cores
- **Memory (RAM):** 2 GB minimum (4 GB+ recommended for running real workloads)
- **Disk:** 20 GB free space

---

## 2. Driver Prerequisites

### Option A: Docker Driver (Recommended)
- Docker Engine must be installed and running:
  ```bash
  docker info
  ```
- Your user must be a member of the `docker` group (to run without `sudo`):
  ```bash
  sudo usermod -aG docker "$USER"
  newgrp docker
  ```

### Option B: KVM2 Driver (Hardware Virtualization)
- CPU must support virtualization:
  ```bash
  grep -E --color 'vmx|svm' /proc/cpuinfo
  ```
- Install KVM and libvirt packages:
  ```bash
  sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
  ```
