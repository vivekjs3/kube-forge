# Minikube Architecture Deep Dive

This document details how Minikube bootstraps an entire Kubernetes system inside an isolated container or hypervisor VM.

---

## 1. The `kicbase` Container Architecture

When using the default `docker` driver:
- Minikube pulls a Docker image named `gcr.io/k8s-minikube/kicbase`.
- This base image contains an entire Debian/Ubuntu root filesystem with `systemd`, `containerd`, and `cri-dockerd` pre-installed.
- Minikube starts a container running `/sbin/init` (systemd).
- Minikube then injects `kubeadm` into the container to initialize the single-node control plane.
- The developer's host communicates with this containerized API server through forwarded TCP ports.
