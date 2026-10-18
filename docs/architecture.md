# RKE2 Architecture Deep Dive

This document details RKE2 process execution, supervisor separation, and embedded etcd management.

---

## 1. Supervisor Separation (Port 9345)

RKE2 runs a supervisor service on HTTPS port `9345`.
- **Purpose:** Manages secure node joining, TLS certificate exchange, and cluster secret dissemination.
- **Why Separate from 6443?** By keeping the Supervisor API on port `9345`, Kubernetes API server traffic (`6443`) is isolated from internal bootstrap traffic, enabling distinct firewall rules and access control policies.

---

## 2. Embedded etcd HA Architecture

In multi-server RKE2 clusters, etcd runs embedded within each `rke2-server` process:
- Initialized on the first server with `token: <SECRET_TOKEN>`.
- Secondary servers join using:
  ```yaml
  server: https://rke2-server-01:9345
  token: <SECRET_TOKEN>
  ```
- RKE2 automatically coordinates Raft member addition to ensure quorum without requiring external etcd management tools.
