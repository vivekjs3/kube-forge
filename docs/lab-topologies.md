# Laboratory Topologies & Infrastructure Design

To facilitate reproducible testing across physical hardware, local virtual machines (KVM, Proxmox, VMware, VirtualBox), or cloud instances, `kube-forge` adopts predictable, standardized laboratory topologies.

---

## 1. Primary Laboratory Topology: Single Control Plane + 2 Workers

This is the standard topology used across the `kubeadm`, `k3s`, `rke2`, `hardway`, and `kubespray` branches.

```
                                  [ Management Host / Laptop ]
                                               |
                                     (SSH / 10.10.10.1/24)
                                               |
         ======================================+======================================
                                     Host Network (10.10.10.0/24)
                                               |
         +-------------------------------------+-------------------------------------+
         |                                     |                                     |
         v                                     v                                     v
+-------------------------+           +-------------------------+           +-------------------------+
|      k8s-control-01     |           |       k8s-worker-01     |           |       k8s-worker-02     |
|   IP: 10.10.10.10       |           |   IP: 10.10.10.11       |           |   IP: 10.10.10.12       |
|   Role: Control Plane   |           |   Role: Worker Node     |           |   Role: Worker Node     |
|   RAM: 4 GB  vCPU: 2    |           |   RAM: 2 GB  vCPU: 2    |           |   RAM: 2 GB  vCPU: 2    |
|   OS: Ubuntu 24.04 LTS  |           |   OS: Ubuntu 24.04 LTS  |           |   OS: Ubuntu 24.04 LTS  |
+-------------------------+           +-------------------------+           +-------------------------+
```

### Static `/etc/hosts` Configuration:
Place this block into `/etc/hosts` on all participating nodes:
```text
# kube-forge laboratory cluster hosts
10.10.10.10  k8s-control-01  k8s-control-01.lab.local
10.10.10.11  k8s-worker-01   k8s-worker-01.lab.local
10.10.10.12  k8s-worker-02   k8s-worker-02.lab.local
```

---

## 2. High-Availability (HA) Topology: 3 Control Planes + Load Balancer

For production validation, an odd number of control planes (minimum 3) is required to sustain etcd quorum failures.

```
                              [ Load Balancer / VIP ]
                              k8s-endpoint.lab.local
                                  (10.10.10.100:6443)
                                          |
                +-------------------------+-------------------------+
                |                         |                         |
                v                         v                         v
     +--------------------+    +--------------------+    +--------------------+
     |   k8s-control-01   |    |   k8s-control-02   |    |   k8s-control-03   |
     |   10.10.10.10      |    |   10.10.10.20      |    |   10.10.10.30      |
     +---------+----------+    +---------+----------+    +---------+----------+
               \                         |                         /
                =========================+=========================
                                         |
                +------------------------+------------------------+
                |                                                 |
                v                                                 v
     +--------------------+                            +--------------------+
     |   k8s-worker-01    |                            |   k8s-worker-02    |
     |   10.10.10.11      |                            |   10.10.10.12      |
     +--------------------+                            +--------------------+
```

### Quorum Tolerance:
- 3 Control Planes: can survive **1** node failure (`(3/2) + 1 = 2` nodes required).
- 5 Control Planes: can survive **2** node failures (`(5/2) + 1 = 3` nodes required).

---

## 3. Minimal Sandbox Topology: Single Node (All-in-One)

Used for `minikube`, `microk8s`, and single-node `k3s` / `kubeadm`:
- **Hostname:** `k8s-standalone-01`
- **IP:** Localhost or private IP (e.g. `192.168.1.50`)
- **Control Plane Taint:** Removed to permit scheduling workloads on the single node:
  ```bash
  kubectl taint nodes --all node-role.kubernetes.io/control-plane-
  ```
