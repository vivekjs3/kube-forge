# Kubeadm Cluster Reset & Node Teardown

This guide documents the safe and complete teardown procedure to uninstall Kubernetes and restore nodes to a pristine state.

---

## ⚠️ Important Warning

> [!WARNING]
> Resetting a node deletes all local container data, pod sandboxes, etcd snapshots, and local certificates. **This operation is irreversible.**
> Ensure any vital application volumes or data are backed up before proceeding.

---

## 1. Automated Teardown Script

To cleanly reset a node, execute the reset script with root privileges:

```bash
sudo ./scripts/reset.sh
```

To run non-interactively without prompting for confirmation:
```bash
sudo ./scripts/reset.sh --force
```

---

## 2. Manual Step-by-Step Reset Procedure

If you prefer to execute the cleanup commands manually, follow these steps:

### Step 1: Drain and Remove Node (From Control Plane)
If the cluster is still online and you are resetting a worker node:
```bash
kubectl drain <node-name> --delete-emptydir-data --force --ignore-daemonsets
kubectl delete node <node-name>
```

### Step 2: Run `kubeadm reset`
On the target node being dismantled:
```bash
sudo kubeadm reset -f
```

### Step 3: Flush Kernel Netfilter & Routing Rules
```bash
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X
sudo iptables -t raw -F

# If IPVS was configured:
if command -v ipvsadm &>/dev/null; then
    sudo ipvsadm --clear
fi
```

### Step 4: Remove CNI Network Interfaces & Links
```bash
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true
sudo ip link delete vxlan.calico 2>/dev/null || true
```

### Step 5: Clean Kubernetes Configuration & State Directories
```bash
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/etcd/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /var/lib/dockershim/
sudo rm -rf /var/run/kubernetes/
sudo rm -rf /etc/cni/net.d/
sudo rm -rf /var/lib/cni/
rm -rf "$HOME/.kube"
```

### Step 6: Restart Container Runtime
To terminate lingering orphan pause containers:
```bash
sudo systemctl restart containerd
```
