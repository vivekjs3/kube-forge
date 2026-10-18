# K3s Architecture Details

This guide explains how K3s achieves high memory efficiency, SQLite translation with Kine, and embedded container execution.

---

## 1. How Kine Translates etcd Calls

In a standard Kubernetes cluster, `kube-apiserver` makes gRPC calls to `etcd` using the etcd v3 protobuf schema.

Kine acts as an in-process RPC translator:
1. It listens on an internal Unix socket pretending to be etcd.
2. When the API server calls `Range()` (read) or `Put()` (write), Kine compiles the key and revision history into SQL queries:
   ```sql
   INSERT INTO kine (name, created, deleted, value, prev_revision) VALUES (...);
   ```
3. SQLite executes the query on disk in `/var/lib/rancher/k3s/server/db/state.db`.
4. This drops the idle memory consumption from ~300MB (for etcd) down to ~20MB (for SQLite).

---

## 2. Server vs. Agent Operational Split

- **`k3s server`**: Executes the control plane (API server, controller manager, scheduler, Kine datastore) and also runs an agent loop locally so that workloads can be scheduled on the server node.
- **`k3s agent`**: Runs exclusively the node components (embedded `kubelet`, embedded `containerd`, embedded `flannel`, and embedded `kube-proxy`). It registers with the server using the server's node token.
