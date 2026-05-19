# ☸️ CKA Practice Laboratory (Blazing-Fast OrbStack Sandbox)

Welcome to the **Ultimate CKA (Certified Kubernetes Administrator) Practice Laboratory**! 

This repository provides a highly optimized, fully automated local sandbox environment designed specifically for macOS using **OrbStack**. It goes far beyond standard VM-based setups by utilizing **instant container machine cloning**, reducing complete 3-node and 5-node cluster spin-ups from **5 minutes to under 15 seconds**!

---

## 🚀 Key Architectural Features

- **⚡ Blazing Fast Cloning Mode**: Pre-bakes optimized base templates (`exam1-base` and `exam2-base`) with core dependencies. Spinning up new environments simply clones from these pre-baked base images instantly.
- **🛠️ Locked Kubernetes Package Versioning**: Exam 2 cluster is initialized at **`v1.35.5`** using APT holds, creating the perfect realistic sandbox to practice **Upgrading Clusters** to `v1.36.1`!
- **🌐 Calico CNI Auto-detection Integration**: Correctly aligns the cluster pod network CIDR (`192.168.0.0/16`) and pre-configures Calico's interface filter matching (`eth0.*`) for OrbStack's lightweight Linux environment, ensuring all nodes transition to `Ready` status instantly.
- **🔌 Ingress & Gateway API Sandboxes**: Helm, Kubernetes Gateway API, and Envoy Gateway are integrated by default in the ready-to-use environments.
- **✅ Multi-Environment Sandboxes**: Support for default single-master networks, multi-master HA layouts (Exam 1), and complete task-validation setups (Exam 2).
- **📋 Automatic Alias & SSH Setup**: Features full shell autocomplete, `k` for `kubectl`, passwordless SSH keys between all cluster nodes, and global `kubeconfig` syncing.

---

## 🏆 Practice Environments

This repository hosts three distinct practice topologies to support your CKA training:

### 1. Default CKA Sandbox (`make up-ready` or `make up-vanilla`)
* **Specs**: 1 Control Plane (`cp-master`), 2 Worker Nodes (`worker-1`, `worker-2`).
* **Vanilla Mode (`make up-vanilla`)**: Installs OS + Container Runtime only. Perfect for manually practicing `kubeadm init`, `kubeadm join`, and bootstrap configuration.
* **Ready Mode (`make up-ready`)**: Installs a fully-configured cluster with Flannel CNI, Helm, and synched kubectl.

### 2. Sander van Vugt Exam 1 HA Sandbox (`make up-exam1`)
* **Specs**: 3 Control Planes (`control1`, `control2`, `control3`), 2 Worker Nodes (`worker1`, `worker2`).
* **Goal**: Focuses on practicing Multi-Master High-Availability (HA) cluster configurations, load balancer setups, and multi-node failure troubleshooting.

### 3. Sander van Vugt Exam 2 Sandbox (`make up-exam2`)
* **Specs**: 1 Control Plane (`control`), 2 Worker Nodes (`worker1`, `worker2`).
* **Goal**: A fully-integrated ready-to-use sandbox supporting the entire Exam 2 curriculum. It comes pre-installed with the complete task verification suite (`~/labs/exam2-grade.sh`).

---

## 🎛️ Command Matrix

Use the following `make` command suite to control all environments:

| Command | Environment | Description |
|---------|-------------|-------------|
| **`make up-vanilla`** | Default | Create default nodes with `containerd` only |
| **`make up-ready`** | Default | Provision and fully initialize default cluster |
| **`make up-exam1`** | Exam 1 | Provision 5-node HA multi-master cluster |
| **`make up-exam2`** | Exam 2 | Provision ready-to-practice 3-node cluster |
| **`make status`** | All | View all active OrbStack containers |
| **`make clean`** | All | Delete all nodes and base images from disk |

### 🔑 SSH Short-Cuts
* **Default Node**: `make ssh-cp`
* **Exam 1 Node 1**: `make ssh-exam1-c1`
* **Exam 2 Master**: `make ssh-exam2-c`
* **Worker Nodes**: You can also use `orb ssh <nodename>` (e.g. `orb ssh worker1`) from any macOS terminal.

---

## 📚 Study Guides & Grading Scripts

We have integrated high-value training assets directly into your workspace:

### 1. Cluster Upgrade Study Guide
* Check out **`upgrade_practice_guide.md`** at your workspace root!
* This premium, CKA-aligned tutorial guides you step-by-step through upgrading the control plane and worker nodes from **v1.35.5** to **v1.36.1**, explaining GPG keyrings, unholding packages, draining nodes, and service reloads.

### 2. Task Verification Grading Suite
When practicing inside the control plane of Exam 2 (`make ssh-exam2-c`), you can run the grading suite to automatically test your configurations:
```bash
~/labs/exam2-grade.sh
```

---

## 🏗️ Technical Prerequisites

- **Host OS**: macOS (Apple Silicon or Intel).
- **OrbStack**: Installed and running ([OrbStack Website](https://orbstack.dev/)).
- **Make**: Available standard on macOS terminal.

---

## 📄 License
MIT License. Created for high-speed local Kubernetes practice.
