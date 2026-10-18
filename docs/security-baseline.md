# Security Baseline & PKI Architecture

Security in Kubernetes begins at the host and network boundaries and extends upward through the cryptographic PKI hierarchy, identity admission, and runtime policies.

---

## 1. Cryptographic Identity & The PKI Hierarchy

Kubernetes uses mutual TLS (mTLS) for authentication and wire encryption across all internal services. No component speaks over unencrypted HTTP.

```
                               +-----------------------------+
                               |     Cluster Root CA         |
                               |  (/etc/kubernetes/pki/ca)   |
                               +--------------+--------------+
                                              |
                   +--------------------------+--------------------------+
                   |                          |                          |
                   v                          v                          v
       +-----------------------+  +-----------------------+  +-----------------------+
       |   API Server Cert     |  |    Kubelet Client     |  |   Controller Manager  |
       |     apiserver.crt     |  |    apiserver-kubelet  |  |    kubeconfig cert    |
       | CN: kube-apiserver    |  | CN: kube-apiserver-   |  | CN: system:kube-      |
       | SANs: IPs & DNS names |  |     kubelet-client    |  |     controller-mgr    |
       +-----------------------+  +-----------------------+  +-----------------------+
```

### Key Certificate Requirements:
1. **API Server SANs (Subject Alternative Names):**
   The API server certificate must contain SANs for:
   - `kubernetes`
   - `kubernetes.default`
   - `kubernetes.default.svc`
   - `kubernetes.default.svc.cluster.local`
   - Control plane node hostname(s)
   - Control plane node static IP(s)
   - Virtual IP / Load Balancer hostname (in HA architectures)
   - Cluster first Service IP (typically `10.96.0.1`)

2. **etcd PKI Separation:**
   etcd should maintain its own independent Certificate Authority (`/etc/kubernetes/pki/etcd/ca.crt`) to prevent compromised workload certificates from accessing the raw datastore directly.

---

## 2. Authentication vs. Authorization

- **Authentication (AuthN):** Who are you?
  - Human operators: Client X.509 certificates (e.g. `CN=admin, O=system:masters`), OpenID Connect (OIDC), or webhook tokens.
  - Pods: ServiceAccount JSON Web Tokens (JWT) projected into container filesystems.
  - Nodes: `system:node:<node-name>` certificates assigned to the `system:nodes` group.
- **Authorization (AuthZ):** What can you do?
  - Handled primarily by **RBAC (Role-Based Access Control)**.
  - Built-in special authorizer: **NodeAuthorizer** ensures a worker node's kubelet can only read Pods scheduled specifically to that node.

---

## 3. CIS Kubernetes Benchmark Alignment

The Center for Internet Security (CIS) produces rigorous benchmarks for hardening Kubernetes. Key platform hardening measures:
- **File Permissions:** `/etc/kubernetes/manifests/*.yaml` must be owned by `root:root` with permissions `600` or `644`.
- **Anonymous Authentication:** Disable `--anonymous-auth=false` on kubelets.
- **Node Restriction:** Enable the `NodeRestriction` admission controller on `kube-apiserver` to restrict kubelet modifications to their own node objects.
- **Token Bound Projection:** Use projected ServiceAccount tokens with short expiration times rather than static long-lived secret tokens.

---

## 4. Repository Security Rules (Zero Secrets)

`kube-forge` enforces strict security hygiene:
1. Never commit `.pem`, `.crt`, `.key`, or `.token` files.
2. Store configuration examples with the `.example` suffix (`kubeadm-config.yaml.example`).
3. Clean up bootstrap tokens after cluster creation.
4. Utilize `.gitignore` to prevent accidental staging of cluster secrets.
