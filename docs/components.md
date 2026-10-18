# MicroK8s Components & Storage Addons

This document details the snap layout and storage provisioners available in MicroK8s.

---

## 1. Storage Addons

MicroK8s offers dynamic storage through two built-in addons:
1. **`hostpath-storage`:** Simple, local dynamic storage provisioner mapping PersistentVolumes to `/var/snap/microk8s/common/default-storage/`.
2. **`mayastor` / `openebs`:** Replicated block storage for multi-node production clusters.
