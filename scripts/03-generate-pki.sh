#!/usr/bin/env bash
# ==============================================================================
# 03-generate-pki.sh — Generate CA and all component TLS certificates via cfssl
# ==============================================================================
set -euo pipefail

INFO="[INFO]"
SUCCESS="[SUCCESS]"
WARN="[WARN]"
ERROR="[ERROR]"

echo "=============================================================================="
echo " kube-forge (hardway) :: Step 03 - PKI Certificate Generation"
echo "=============================================================================="

PKI_DIR="tls"
mkdir -p "${PKI_DIR}"
cd "${PKI_DIR}"

# 1. Certificate Authority Config & CSR
echo "${INFO} 1. Generating Cluster Root Certificate Authority (CA)..."
cat <<EOF > ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "87600h"
      }
    }
  }
}
EOF

cat <<EOF > ca-csr.json
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "San Francisco",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "California"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca
echo "${SUCCESS} Generated ca.pem and ca-key.pem."

# 2. Admin Client Certificate
echo "${INFO} 2. Generating Admin Client Certificate (system:masters)..."
cat <<EOF > admin-csr.json
{
  "CN": "admin",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [
    { "C": "US", "L": "San Francisco", "O": "system:masters", "OU": "Kubernetes The Hard Way", "ST": "California" }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

# 3. Kubelet Client Certificates (Worker)
WORKER_NAME="k8s-worker-01"
echo "${INFO} 3. Generating Kubelet Certificate for ${WORKER_NAME}..."
cat <<EOF > ${WORKER_NAME}-csr.json
{
  "CN": "system:node:${WORKER_NAME}",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [
    { "C": "US", "L": "San Francisco", "O": "system:nodes", "OU": "Kubernetes The Hard Way", "ST": "California" }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${WORKER_NAME},10.10.10.11,127.0.0.1 -profile=kubernetes ${WORKER_NAME}-csr.json | cfssljson -bare ${WORKER_NAME}

# 4. kube-controller-manager Client Certificate
echo "${INFO} 4. Generating kube-controller-manager Client Certificate..."
cat <<EOF > kube-controller-manager-csr.json
{
  "CN": "system:kube-controller-manager",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [
    { "C": "US", "L": "San Francisco", "O": "system:kube-controller-manager", "OU": "Kubernetes The Hard Way", "ST": "California" }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

# 5. kube-proxy Client Certificate
echo "${INFO} 5. Generating kube-proxy Client Certificate..."
cat <<EOF > kube-proxy-csr.json
{
  "CN": "system:kube-proxy",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [
    { "C": "US", "L": "San Francisco", "O": "system:node-proxier", "OU": "Kubernetes The Hard Way", "ST": "California" }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy

# 6. kube-scheduler Client Certificate
echo "${INFO} 6. Generating kube-scheduler Client Certificate..."
cat <<EOF > kube-scheduler-csr.json
{
  "CN": "system:kube-scheduler",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [
    { "C": "US", "L": "San Francisco", "O": "system:kube-scheduler", "OU": "Kubernetes The Hard Way", "ST": "California" }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler

# 7. Kubernetes API Server Certificate (with SANs)
echo "${INFO} 7. Generating API Server Server Certificate..."
cat <<EOF > kubernetes-csr.json
{
  "CN": "kubernetes",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [
    { "C": "US", "L": "San Francisco", "O": "Kubernetes", "OU": "Kubernetes The Hard Way", "ST": "California" }
  ]
}
EOF

# SANs: Internal ClusterIP 10.32.0.1, Control Plane IP 10.10.10.10, localhost, and DNS hostnames
KUBERNETES_HOSTNAMES="10.32.0.1,10.10.10.10,127.0.0.1,localhost,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local"

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${KUBERNETES_HOSTNAMES} -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

# 8. Service Account Token Signing Keypair
echo "${INFO} 8. Generating Service Account Keypair..."
cat <<EOF > service-account-csr.json
{
  "CN": "service-accounts",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [
    { "C": "US", "L": "San Francisco", "O": "Kubernetes", "OU": "Kubernetes The Hard Way", "ST": "California" }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes service-account-csr.json | cfssljson -bare service-account

echo "=============================================================================="
echo "${SUCCESS} Step 03 All PKI Certificates Generated in $(pwd)!"
echo "=============================================================================="
