# Talos Linux Networking Architecture

Talos manages network interfaces declaratively and provides built-in Layer 2 Virtual IP (VIP) support for control planes.

---

## 1. Control Plane Virtual IP (VIP)

In multi-node HA control plane setups, Talos can automatically elect an active VIP via ARP announcements without requiring an external load balancer or Keepalived daemon:
```yaml
machine:
  network:
    interfaces:
      - interface: eth0
        vip:
          ip: 10.10.10.100
```
This VIP functions as the resilient entry point for `kube-apiserver` on port 6443.
