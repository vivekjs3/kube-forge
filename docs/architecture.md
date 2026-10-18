# MicroK8s Architecture Deep Dive

This document details the mechanics of MicroK8s snap architecture, command aliases, and multi-node Dqlite clustering.

---

## 1. Dqlite Multi-Node Clustering

When multiple MicroK8s nodes form a cluster:
- If cluster size is < 3 nodes: The first node acts as the active control plane.
- If cluster size is >= 3 nodes: MicroK8s automatically converts the cluster into a High-Availability (HA) topology, forming a 3-way Raft quorum with Dqlite.
- If an active control plane fails, the remaining Dqlite nodes elect a new leader automatically.
