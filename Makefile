IMAGE = ubuntu:24.04

# Default environment nodes
NODES = cp-master worker-1 worker-2
WORKERS = worker-1 worker-2

# Exam 1 environment nodes (3 Control Planes, 2 Workers)
EXAM1_NODES = control1 control2 control3 worker1 worker2
EXAM1_WORKERS = worker1 worker2

# Exam 2 environment nodes (1 Control Plane, 2 Workers)
EXAM2_NODES = control worker1 worker2
EXAM2_WORKERS = worker1 worker2

.PHONY: help up-vanilla up-ready clean status ssh-cp ssh-w1 ssh-w2 push-labs up-exam1 up-exam2 ssh-exam1-c1 ssh-exam1-c2 ssh-exam1-c3 ssh-exam1-w1 ssh-exam1-w2 ssh-exam2-c ssh-exam2-w1 ssh-exam2-w2 install-calico

help:
	@echo "CKA Practice Environment Management"
	@echo "-----------------------------------"
	@echo "make up-vanilla  : Spin up 3 nodes with containerd (default env)"
	@echo "make up-ready    : Spin up 3 nodes and fully initialize the cluster (default env)"
	@echo "make up-exam1    : Spin up 5 nodes for Exam 1 (control1, control2, control3, worker1, worker2)"
	@echo "make up-exam2    : Spin up 3 nodes and initialize cluster for Exam 2 (control, worker1, worker2)"
	@echo "make clean       : Destroy all machines across all environments"
	@echo "make status      : Show machine status"
	@echo "-----------------------------------"
	@echo "SSH Shortcuts:"
	@echo "make ssh-cp      : SSH into cp-master (default env)"
	@echo "make ssh-exam1-c1: SSH into control1 (Exam 1)"
	@echo "make ssh-exam2-c : SSH into control (Exam 2)"

# ==========================================
# DEFAULT ENVIRONMENT
# ==========================================

up-vanilla:
	@echo ">>> Creating machines..."
	@for node in $(NODES); do \
		orb create $(IMAGE) $$node 2>/dev/null || echo "$$node already exists"; \
		orb start $$node; \
	done
	@echo ">>> Running common setup on all nodes (swap off, modules, containerd)..."
	@for node in $(NODES); do \
		echo "Configuring $$node..."; \
		orb run -m $$node bash scripts/common.sh || exit 1; \
	done

up-ready: up-vanilla
	@echo ">>> Configuring hostname resolution..."
	@bash scripts/setup-hosts.sh $(NODES) || exit 1
	@echo ">>> Installing Kubernetes components (kubelet, kubeadm, kubectl)..."
	@for node in $(NODES); do \
		echo "Installing K8s on $$node..."; \
		orb run -m $$node bash scripts/k8s-install.sh || exit 1; \
	done
	@echo ">>> Initializing Master..."
	@orb run -m cp-master bash scripts/master.sh || exit 1
	@echo ">>> Joining Workers..."
	@# join-command.sh is created in the root directory by master.sh via mapped drive
	@for worker in $(WORKERS); do \
		echo "Joining $$worker..."; \
		orb run -m $$worker sudo sh ./join-command.sh || exit 1; \
	done
	@rm -f join-command.sh
	@echo ">>> Syncing kubeconfig to all nodes..."
	@orb run -m cp-master bash -c "sudo cp /etc/kubernetes/admin.conf ~/.kube/config && sudo chown \$$(id -u):\$$(id -g) ~/.kube/config && cat ~/.kube/config" > .kubeconfig-temp
	@for node in $(NODES); do \
		echo "Syncing config to $$node..."; \
		orb run -m $$node bash -c "mkdir -p ~/.kube && cat > ~/.kube/config" < .kubeconfig-temp || exit 1; \
	done
	@rm .kubeconfig-temp
	@echo ">>> Installing Helm on cp-master..."
	@orb run -m cp-master bash scripts/helm-install.sh || exit 1
	@echo ">>> Installing Gateway API and Envoy Gateway on cp-master..."
	@orb run -m cp-master bash scripts/gateway-install.sh || exit 1
	@$(MAKE) push-labs
	@echo ">>> Cluster is ready!"
	@echo ">>> Run 'make ssh-cp' to access the control plane."

push-labs:
	@echo ">>> Preparing lab scripts..."
	@# Lab scripts are already accessible via mapped directory.
	@orb run -m cp-master bash -c "chmod +x scripts/*.sh"
	@orb run -m cp-master bash -c "mkdir -p ~/labs && ln -sf \$$(pwd)/scripts/etcd-backup.sh ~/labs/etcd-backup.sh"
	@orb run -m cp-master bash -c "ln -sf \$$(pwd)/scripts/etcd-restore.sh ~/labs/etcd-restore.sh"
	@orb run -m cp-master bash -c "ln -sf \$$(pwd)/labs/netpol-lab.yaml ~/labs/netpol-lab.yaml"

# ==========================================
# EXAM 1 ENVIRONMENT (Multi-Master Prep)
# ==========================================

up-exam1:
	@echo ">>> Orchestrating Exam 1 environment setup (Blazing Fast Cloning Mode)..."
	@bash scripts/install-sander-cka.sh || exit 1
	@echo ">>> Exam 1 environment setup complete!"
	@echo ">>> All 5 nodes are ready, hostnames are resolved, and passwordless sudo is configured."
	@echo ">>> Sander van Vugt scripts (CRI, kubetools, load balancer) are fully installed."
	@echo ">>> Control Plane Nodes: control1, control2, control3"
	@echo ">>> Worker Nodes: worker1, worker2"
	@echo ">>> Run 'make ssh-exam1-c1' to SSH into the first control plane node."

# ==========================================
# EXAM 2 ENVIRONMENT (Single Master Ready-to-Practice)
# ==========================================

up-exam2:
	@echo ">>> Orchestrating Exam 2 environment setup (Blazing Fast Cloning Mode)..."
	@bash scripts/install-exam2.sh || exit 1

# ==========================================
# UTILITIES & MANAGEMENT
# ==========================================

install-calico:
	@echo ">>> Installing Calico CNI on control1..."
	@orb run -m control1 bash scripts/install-calico.sh

clean:
	@echo ">>> Deleting all nodes and base images from all environments..."
	@for node in $(NODES) $(EXAM1_NODES) $(EXAM2_NODES) exam1-base exam2-base; do \
		orb delete -f $$node 2>/dev/null || true; \
	done

status:
	@orb list

# SSH Shortcuts
ssh-cp:
	@orb run -m cp-master
ssh-w1:
	@orb run -m worker-1
ssh-w2:
	@orb run -m worker-2

# Exam 1 SSH
ssh-exam1-c1:
	@orb run -m control1
ssh-exam1-c2:
	@orb run -m control2
ssh-exam1-c3:
	@orb run -m control3
ssh-exam1-w1:
	@orb run -m worker1
ssh-exam1-w2:
	@orb run -m worker2

# Exam 2 SSH
ssh-exam2-c:
	@orb run -m control
ssh-exam2-w1:
	@orb run -m worker1
ssh-exam2-w2:
	@orb run -m worker2
