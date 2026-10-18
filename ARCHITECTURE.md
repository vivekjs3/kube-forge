# Kubernetes The Hard Way: Architecture & Internals

This document details the architecture of a manual, bare-metal Kubernetes deployment where all components run as native Linux `systemd` services.

---

## 1. Systemd Native Architecture

Unlike `kubeadm` (which uses static pods) or `k3s` (which uses a single multi-call binary), Kubernetes The Hard Way executes each component as a dedicated systemd service unit.

```
+-------------------------------------------------------------------------------+
|                            CONTROL PLANE HOST (Linux)                         |
|                                                                               |
|   +-----------------------------------------------------------------------+   |
|   |                            systemd Services                           |   |
|   |                                                                       |   |
|   |  +------------------------+             +--------------------------+  |   |
|   |  |     etcd.service       |             |   kube-apiserver.service |  |   |
|   |  |   (/usr/local/bin/etcd)|             | (/usr/local/bin/kube-api)|  |   |
|   |  |   Listens: 2379 / 2380 |             | Listens: 6443            |  |   |
|   |  +-----------^------------+             +------------^-------------+  |   |
|   |              |                                       |                |   |
|   |              +================mTLS===================+                |   |
|   |                                                      |                |   |
|   |  +---------------------------+          +------------+-------------+  |   |
|   |  | kube-controller-manager   |          |  kube-scheduler.service  |  |   |
|   |  |       .service            |          | (/usr/local/bin/kube-    |  |   |
|   |  | Listens: internal 10257   |          |      scheduler)          |  |   |
|   |  +-------------+-------------+          +------------+-------------+  |   |
|   |                |                                     |                |   |
|   |                +==============mTLS===================+                |   |
|   +-----------------------------------------------------------------------+   |
+-------------------------------------------------------------------------------+
                                       |
                                       | mTLS across Port 6443
                                       v
+-------------------------------------------------------------------------------+
|                             WORKER NODE HOST (Linux)                          |
|                                                                               |
|   +-----------------------------------------------------------------------+   |
|   |                            systemd Services                           |   |
|   |                                                                       |   |
|   |  +------------------------+             +--------------------------+  |   |
|   |  |   containerd.service   | <---gRPC--- |     kubelet.service      |  |   |
|   |  | (/usr/local/bin/       |  Unix Sock  |  (/usr/local/bin/kubelet)|  |   |
|   |  |     containerd)        |             |  Listens: 10250          |  |   |
|   |  +-----------+------------+             +--------------------------+  |   |
|   |              |                                                        |   |
|   |              v (runc & CNI bridge)      +--------------------------+  |   |
|   |  +------------------------+             |    kube-proxy.service    |  |   |
|   |  |    Container Pods      |             | (/usr/local/bin/         |  |   |
|   |  |      (cbr0 veth)       |             |     kube-proxy)          |  |   |
|   |  +------------------------+             +--------------------------+  |   |
|   +-----------------------------------------------------------------------+   |
+-------------------------------------------------------------------------------+
```

---

## 2. Complete PKI Certificate Graph

Security in a manual cluster is entirely governed by TLS X.509 certificates. The diagram below illustrates which certificate authenticates which component:

```
                            +--------------------------------+
                            |     Cluster Root CA (ca.pem)   |
                            +---------------+----------------+
                                            |
         +----------------------------------+----------------------------------+
         |                                  |                                  |
         v                                  v                                  v
+-------------------+              +-------------------+              +-------------------+
|  apiserver.pem    |              |   worker.pem      |              |    admin.pem      |
|  Server TLS for   |              |  Client cert for  |              |  Client cert with |
|  API Server (6443)|              |  Kubelet (mTLS)   |              |  system:masters   |
+-------------------+              +-------------------+              +-------------------+
         |                                  |                                  |
         v                                  v                                  v
+-------------------+              +-------------------+              +-------------------+
|  kube-proxy.pem   |              | controller-mgr.pem|              |   scheduler.pem   |
|  Client cert for  |              | Client cert for   |              |  Client cert for  |
|  kube-proxy       |              | controller manager|              |  kube-scheduler   |
+-------------------+              +-------------------+              +-------------------+
```

---

## 3. Directory Layout on Control Plane

```text
/etc/etcd/
├── ca.pem
├── kubernetes.pem
└── kubernetes-key.pem

/var/lib/etcd/                      # etcd data directory

/var/lib/kubernetes/
├── ca.pem & ca-key.pem             # Root CA
├── kubernetes.pem & key            # API Server cert
├── service-account.pem & key       # SA Token signer
├── encryption-config.yaml          # Secret encryption at rest config
├── kube-controller-manager.kubeconfig
└── kube-scheduler.kubeconfig

/etc/systemd/system/
├── etcd.service
├── kube-apiserver.service
├── kube-controller-manager.service
└── kube-scheduler.service
```
