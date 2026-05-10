# CKA Practice Lab (OrbStack)

A fast, automated environment for CKA (Certified Kubernetes Administrator) practice on macOS using **OrbStack**.

This repository provides a `Makefile` and a set of scripts to quickly spin up a 3-node Kubernetes cluster (1 Control Plane, 2 Worker Nodes) using lightweight OrbStack Linux machines.

## Features

- **Speed**: Bring up a full cluster in minutes.
- **Two Environments**:
  - `make up-vanilla`: OS + Container Runtime only. Perfect for practicing `kubeadm init` and manual installation.
  - `make up-ready`: Fully initialized cluster with CNI (Flannel) and synced `kubeconfig`.
- **Pre-configured Aliases**: `k` for `kubectl`, bash completion, and standard CKA aliases are set up automatically.
- **Practice Labs**: Includes scripts and YAMLs for practicing:
  - Etcd Snapshot & Restore.
  - Network Policies.
- **Auto-Sync**: `kubeconfig` is automatically synced to all nodes so you can run `kubectl` from anywhere.

## Prerequisites

- [OrbStack](https://orbstack.dev/) installed on macOS.
- `make` installed (standard on macOS).

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/realplord/jung-k8s-lab.git
   cd jung-k8s-lab
   ```

2. **Spin up a ready-to-use cluster**:
   ```bash
   make up-ready
   ```

3. **Access the control plane**:
   ```bash
   make ssh-cp
   ```

4. **Verify the cluster**:
   ```bash
   k get nodes
   ```

## Management Commands

| Command | Description |
|---------|-------------|
| `make up-vanilla` | Create nodes with `containerd` only (for install practice) |
| `make up-ready` | Full cluster initialization |
| `make clean` | Delete all OrbStack machines |
| `make status` | List machine status |
| `make ssh-cp` | SSH into the Control Plane |
| `make ssh-w1` | SSH into Worker 1 |
| `make ssh-w2` | SSH into Worker 2 |
| `make push-labs` | Re-sync lab scripts to the master node |

## Practice Labs

Once inside the Control Plane (`make ssh-cp`), check the `~/labs` directory:
- `etcd-backup.sh`: Practice taking etcd snapshots.
- `etcd-restore.sh`: Template for etcd restoration practice.
- `netpol-lab.yaml`: A multi-namespace network policy scenario.

## License

MIT
