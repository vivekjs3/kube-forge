# Minikube Troubleshooting Guide

This guide details common failures encountered when launching and testing **Minikube**, organized by **Problem -> Cause -> Check -> Fix -> Validation**.

---

## 1. Docker Permission Denied

### Problem:
`minikube start --driver=docker` fails with:
`permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock`

### Cause:
The current Linux user does not have permission to access the Docker daemon socket.

### Check:
```bash
docker ps
```

### Fix:
Add your user to the `docker` group and refresh your login session:
```bash
sudo usermod -aG docker "$USER"
newgrp docker
```

### Validation:
```bash
docker ps
# Command returns cleanly without sudo
```

---

## 2. Inability to Access `type: LoadBalancer` Services

### Problem:
Service shows `EXTERNAL-IP: <pending>`.

### Cause:
Local Kubernetes environments do not have a physical cloud load balancer.

### Check:
```bash
kubectl get svc
```

### Fix:
Run `minikube tunnel` in a separate terminal window:
```bash
minikube tunnel
```
This maps route tables to assign real routable external IPs to your services.

### Validation:
```bash
kubectl get svc
# EXTERNAL-IP changes from <pending> to a concrete IP (e.g. 10.96.x.x or 127.0.0.1)
```

---

## 3. Corrupted Cluster State or Failed Startup

### Problem:
Minikube hangs at `Waiting for API server to become available...` or crashes with mismatched state.

### Fix:
Completely delete the sandbox profile and restart cleanly:
```bash
minikube delete --all --purge
minikube start --driver=docker
```
