#!/usr/bin/env bash
# ==============================================================================
# 06-install-control-plane.sh — Install API Server, Controller Manager, Scheduler
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

K8S_VER="v1.31.0"
ARCH=$(dpkg --print-architecture)

echo "=============================================================================="
echo " kube-forge (hardway) :: Step 06 - Control Plane Systemd Installation"
echo "=============================================================================="

if [[ $EUID -ne 0 ]]; then
    echo "${ERROR} This script must be executed as root or with sudo." >&2
    exit 1
fi

INTERNAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n 1 || hostname -I | awk '{print $1}')

# 1. Download Control Plane Binaries
mkdir -p /var/lib/kubernetes/ /etc/kubernetes/config/
for bin in kube-apiserver kube-controller-manager kube-scheduler kubectl; do
    if ! command -v "$bin" &>/dev/null; then
        echo "${INFO} Downloading ${bin} ${K8S_VER}..."
        wget -q --show-progress "https://dl.k8s.io/${K8S_VER}/bin/linux/${ARCH}/${bin}"
        chmod +x "${bin}"
        mv "${bin}" /usr/local/bin/
    fi
done
echo "${SUCCESS} Kubernetes control plane binaries installed in /usr/local/bin/."

# 2. Copy certificates and kubeconfigs
if [[ -d tls && -d kubeconfigs ]]; then
    cp tls/ca.pem tls/ca-key.pem tls/kubernetes.pem tls/kubernetes-key.pem \
       tls/service-account.pem tls/service-account-key.pem /var/lib/kubernetes/
    cp kubeconfigs/kube-controller-manager.kubeconfig /var/lib/kubernetes/
    cp kubeconfigs/kube-scheduler.kubeconfig /var/lib/kubernetes/
    chmod 600 /var/lib/kubernetes/*key.pem 2>/dev/null || true
fi

# 3. Secret Encryption Configuration
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat <<EOF > /var/lib/kubernetes/encryption-config.yaml
kind: EncryptionConfiguration
apiVersion: apiserver.config.k8s.io/v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

# 4. Systemd Unit: kube-apiserver
echo "${INFO} Writing /etc/systemd/system/kube-apiserver.service..."
cat <<EOF > /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
After=network.target etcd.service

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=1 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://127.0.0.1:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --runtime-config=api/all=true \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-account-signing-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-account-issuer=https://${INTERNAL_IP}:6443 \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 5. Systemd Unit: kube-controller-manager
echo "${INFO} Writing /etc/systemd/system/kube-controller-manager.service..."
cat <<EOF > /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
After=network.target kube-apiserver.service

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 6. Systemd Unit: kube-scheduler
echo "${INFO} Writing /etc/systemd/system/kube-scheduler.service..."
cat <<EOF > /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
After=network.target kube-apiserver.service

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig \\
  --leader-elect=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 7. Start Services
systemctl daemon-reload
systemctl enable --now kube-apiserver kube-controller-manager kube-scheduler

echo "${INFO} Waiting for control plane services to stabilize..."
sleep 5

# 8. RBAC for Kubelet API Access
echo "${INFO} Applying RBAC ClusterRole for API Server to Kubelet communication..."
export KUBECONFIG="kubeconfigs/admin.kubeconfig"

kubectl apply -f - <<EOF || true
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF

echo "=============================================================================="
echo "${SUCCESS} Step 06 Control Plane Services Active!"
echo "=============================================================================="
