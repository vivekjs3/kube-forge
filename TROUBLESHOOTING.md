# Kubespray Troubleshooting Guide

This guide details common failures encountered during **Kubespray** automation runs, following the **Problem -> Cause -> Check -> Fix -> Validation** protocol.

---

## 1. SSH Authentication Failure: `Permission denied (publickey)`

### Problem:
Ansible execution aborts:
`k8s-control-01 | UNREACHABLE! => {"msg": "Failed to connect to the host via ssh: Permission denied (publickey)..."}`

### Cause:
SSH key not present on the target node, or wrong SSH user specified in `ansible_user`.

### Fix:
Verify SSH connectivity directly:
```bash
ssh -i ~/.ssh/id_ed25519 <USER>@10.10.10.10
```
Distribute the key if missing:
```bash
ssh-copy-id -i ~/.ssh/id_ed25519 <USER>@10.10.10.10
```

### Validation:
```bash
ansible -i inventory/mycluster/inventory.ini all -m ping
# All nodes must report "pong" with SUCCESS
```

---

## 2. Python Dependency Conflicts on Controller Host

### Problem:
Running `ansible-playbook` fails with `ModuleNotFoundError` or incompatible cryptography/urllib3 version errors.

### Cause:
Packages installed directly into global system Python rather than an isolated virtual environment.

### Fix:
Use a clean virtualenv as instructed in `01-prerequisites.sh`:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r kubespray/requirements.txt
```

---

## 3. Playbook Task Failure During Binary Download

### Problem:
Playbook fails on `download_file` task due to slow internet or checksum mismatch.

### Fix:
Re-run the playbook with the `--tags=download` or simply re-run `cluster.yml`. Kubespray playbooks are idempotent and will resume from failed tasks.
