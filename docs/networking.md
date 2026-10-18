# Minikube Networking Patterns

Accessing applications running inside Minikube requires different techniques than accessing bare-metal nodes.

---

## 1. Access Modes

1. **`kubectl port-forward`:**
   Directly forwards a local host port to a pod or service:
   ```bash
   kubectl port-forward svc/my-service 8080:80
   ```
2. **`minikube service`:**
   Opens a NodePort service in your default web browser automatically:
   ```bash
   minikube service my-service
   ```
3. **`minikube tunnel`:**
   Runs as a network bridge daemon, creating a virtual route allowing direct browser access to Service `LoadBalancer` IPs.
