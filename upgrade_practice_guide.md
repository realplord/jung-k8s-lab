# 🚀 CKA Cluster Upgrade Practice Guide (v1.35.x ➜ v1.36.x)

This guide walks you through upgrading your practice cluster from **v1.35.5** to the latest stable **v1.36.1**. In the actual CKA exam, cluster upgrades are a high-weight task worth 10-15% of your total score.

---

## 📋 The Upgrade Workflow Overview

Upgrading a cluster must always be done in the following strict order to prevent service disruption:
1. **Control Plane Node (Master)**:
   - Upgrade `kubeadm` package.
   - Run `kubeadm upgrade plan` & `kubeadm upgrade apply`.
   - Upgrade `kubelet` and `kubectl` packages on the master.
2. **Worker Nodes (One-by-one)**:
   - Upgrade `kubeadm` package on the worker node.
   - Run `kubeadm upgrade node`.
   - Upgrade `kubelet` and `kubectl` packages on the worker node.

> [!IMPORTANT]
> The packages on the nodes are locked using `apt-mark hold` to prevent accidental updates. You **must** unhold them before upgrading, and re-hold them immediately afterward.

---

## 🛠️ Step 1: Upgrading the Control Plane Node (`control`)

First, log into the control plane node from your host system:
```bash
make ssh-exam2-c
```

### 1. Update the Repository and Keyring to the Target Version (`v1.36`)
Because Kubernetes repositories in `pkgs.k8s.io` are organized by minor version, you must update the apt list URL and fetch the new GPG release key for the target version (`v1.36`).

```bash
# Fetch the v1.36 GPG keyring
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Point sources.list.d to v1.36
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Refresh apt cache
sudo apt-get update
```

### 2. Upgrade `kubeadm`
```bash
# 1. Unhold kubeadm
sudo apt-mark unhold kubeadm

# 2. Install target kubeadm version
sudo apt-get install -y kubeadm=1.36.1-1.1

# 3. Lock kubeadm back
sudo apt-mark hold kubeadm
```

Verify that the version has updated:
```bash
kubeadm version
```

### 3. Plan and Apply the Cluster Upgrade
Run the plan to check compatibility and see what components will be upgraded:
```bash
sudo kubeadm upgrade plan
```

Apply the upgrade to the static pods, configurations, and core addons (CoreDNS and kube-proxy):
```bash
sudo kubeadm upgrade apply v1.36.1 -y
```

---

## 🧹 Step 2: Draining and Upgrading Kubelet/Kubectl on Master

After `kubeadm` completes the static pod upgrades, you must upgrade the node agent (`kubelet`) and the CLI (`kubectl`) on the master node.

### 1. Drain the Master Node
Before upgrading `kubelet`, evict or reschedule all pods currently running on the master:
```bash
kubectl drain control --ignore-daemonsets --delete-emptydir-data --force
```

> [!NOTE]
> If a pod (like `calico-apiserver`) is blocked by a PodDisruptionBudget in a single-master layout, you can bypass it by forcefully deleting that pod from another terminal session or using `--disable-eviction=true` (if available on the exam cluster).
> ```bash
> kubectl delete pod -n calico-apiserver <pod-name> --grace-period=0 --force
> ```

### 2. Upgrade Kubelet and Kubectl Packages
```bash
# 1. Release locks
sudo apt-mark unhold kubelet kubectl

# 2. Upgrade packages
sudo apt-get install -y kubelet=1.36.1-1.1 kubectl=1.36.1-1.1

# 3. Lock packages
sudo apt-mark hold kubelet kubectl
```

### 3. Restart Kubelet Service
```bash
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### 4. Uncordon the Master Node
Wait a few seconds for the api-server static pod to restart and boot up, then run:
```bash
kubectl uncordon control
```

Verify that the master node is now showing `v1.36.1`:
```bash
kubectl get nodes
```

---

## 🎁 Bonus: Upgrading Worker Nodes (`worker1`, `worker2`)

In the actual exam, you will also be asked to upgrade the worker nodes. You can practice this right in this environment!

Perform these steps on each worker node (e.g. `worker1`):

### 1. Cordon and Drain the Worker from the Master Node
**Inside the master node (`control`)**, cordon and drain the worker node:
```bash
kubectl drain worker1 --ignore-daemonsets --delete-emptydir-data --force
```

### 2. Access the Worker Node
Open a new terminal window on your host macOS system, and SSH into the worker node:
```bash
orb ssh worker1
```

### 3. Update the Repository and Keyring to `v1.36`
```bash
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
```

### 4. Upgrade `kubeadm` on the Worker
```bash
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.36.1-1.1
sudo apt-mark hold kubeadm
```

### 5. Upgrade the Local Kubelet Configuration
```bash
sudo kubeadm upgrade node
```

### 6. Upgrade `kubelet` and `kubectl` on the Worker
```bash
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.36.1-1.1 kubectl=1.36.1-1.1
sudo apt-mark hold kubelet kubectl
```

### 7. Restart Kubelet Service
```bash
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

### 8. Uncordon the Worker Node
**Go back to the master node (`control`)** and mark the worker as schedulable:
```bash
kubectl uncordon worker1
```

### 9. Verify
Run `kubectl get nodes` to confirm `worker1` is now showing `v1.36.1` and is in the `Ready` status!

---

## 🏆 Validate Your Solution
At any point, run the grading script on the master node to evaluate your work:
```bash
~/labs/exam2-grade.sh
```
