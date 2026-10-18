# Kubespray Playbook Suite

This document outlines the core playbooks provided by Kubespray for cluster lifecycle operations:
- **`cluster.yml`**: Provisions or reconciles the full cluster.
- **`scale.yml`**: Adds worker nodes to an existing running cluster.
- **`upgrade-cluster.yml`**: Orchestrates rolling node cordon, drain, upgrade, and uncordon.
- **`remove-node.yml`**: Safely evicts and decommission a node from the cluster.
- **`reset.yml`**: Tears down all components and restores target nodes to clean state.
