# Minikube Architecture & Driver Models

This document details the architectural internals of **Minikube** and explains how it simulates a complete Kubernetes environment on a single machine.

---

## 1. Driver Execution Models

Minikube relies on an abstraction layer called a **Driver** to isolate the Kubernetes cluster from your host operating system:

| Driver | Isolation Type | Overhead | Best For | Caveats |
|---|---|---|---|---|
| **`docker`** (Default) | Containerized | Minimal (~100MB) | Modern Linux, macOS, Windows with Docker installed | Requires running Docker daemon; shared host kernel |
| **`kvm2`** | Hardware VM | Moderate (~500MB) | Pure Linux workstations, nested virtualization | Requires CPU VT-x/AMD-v virtualization extensions |
| **`podman`** | Rootless Container | Minimal | Environments without root/Docker daemon | Rootless network configuration overhead |
| **`none`** | Bare-Host Native | Zero | Dedicated CI/CD runners only | **Pollutes host filesystem**; runs components directly as root |

---

## 2. In-Sandbox Cluster Mechanics

When Minikube boots using the `docker` driver:
1. It launches a dedicated base container (`gcr.io/k8s-minikube/kicbase`).
2. Inside that container, a full `systemd` init process starts.
3. Kubelet, containerd, and standard Kubernetes static pods (`kube-apiserver`, `etcd`, `kube-controller-manager`, `kube-scheduler`) initialize exactly as they would on a physical node running `kubeadm`.
4. Minikube generates an external client certificate and writes a custom `kubeconfig` pointing to the sandbox container's mapped IP and port.
