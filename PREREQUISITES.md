# Kubespray Prerequisites & Infrastructure Requirements

Before running Kubespray automation, both the Ansible controller machine and all target nodes must meet these prerequisites.

---

## 1. Ansible Controller Requirements

The controller host (the machine running the playbooks) needs:
- **Operating System:** Linux or macOS
- **Python:** Python 3.10, 3.11, or 3.12
- **Tools:** `git`, `python3-pip`, `python3-virtualenv`
- **Network Access:** SSH connectivity (port 22) to all target nodes

---

## 2. Target Nodes Requirements

| Node Type | Minimum vCPU | Recommended vCPU | Minimum RAM | Recommended RAM |
|---|---|---|---|---|
| **Control Plane** | 2 vCPU | 2-4 vCPU | 2 GB | 4 GB |
| **Worker Node** | 1 vCPU | 2 vCPU | 1.5 GB | 2 GB |

- **Operating System:** Ubuntu 22.04 / 24.04 LTS, Debian 11/12, Rocky Linux 8/9, RHEL 8/9.
- **Python:** Target nodes must have `python3` installed.
- **Privileges:** The SSH user must have passwordless `sudo` privileges.

---

## 3. SSH Key Setup & Distribution

Generate an SSH key on your Ansible controller and copy it to all target nodes:
```bash
# 1. Generate SSH key (if not already present)
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519

# 2. Copy public key to all nodes
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@10.10.10.10
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@10.10.10.11
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@10.10.10.12

# 3. Test connectivity without password
ssh user@10.10.10.10 "sudo whoami"
# Must output: root
```
