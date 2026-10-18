# Kubespray Networking & CNI Options

Kubespray supports numerous CNI plugins configured via `kube_network_plugin` in `k8s-cluster.yml`:
- **`calico`** (Default): Supports Calico IPAM, BGP, and VXLAN modes.
- **`cilium`**: High-performance eBPF networking and security observability.
- **`flannel`**: Simple VXLAN overlay networking.
- **`kube-ovn`**: Advanced enterprise Open vSwitch networking.
