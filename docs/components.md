# Minikube Components & Addon System

This document outlines the Minikube command line tool and its addon architecture.

---

## 1. Minikube CLI Architecture

- **`minikube` binary:** Acts as orchestrator, VM/container provisioner, certificate generator, and addon manager.
- **Config Storage:** Lives under `$HOME/.minikube/` containing ISO caches, VM disks, profiles, and certificates.

---

## 2. The Addon System

Minikube features an integrated addon manager that injects pre-tested Kubernetes manifests with a single flag:
```bash
minikube addons list
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard
```
