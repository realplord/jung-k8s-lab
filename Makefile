IMAGE = ubuntu:24.04
NODES = cp-master worker-1 worker-2
WORKERS = worker-1 worker-2

.PHONY: help up-vanilla up-ready clean status ssh-cp ssh-w1 ssh-w2 push-labs

help:
	@echo "CKA Practice Environment Management"
	@echo "-----------------------------------"
	@echo "make up-vanilla  : Spin up 3 nodes with containerd"
	@echo "make up-ready    : Spin up 3 nodes and fully initialize the cluster"
	@echo "make clean       : Destroy all machines"
	@echo "make status      : Show machine status"
	@echo "make ssh-cp      : SSH into master"
	@echo "make ssh-w1      : SSH into worker-1"
	@echo "make ssh-w2      : SSH into worker-2"

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

clean:
	@echo ">>> Deleting all nodes..."
	@for node in $(NODES); do \
		orb delete -f $$node 2>/dev/null || true; \
	done

status:
	@orb list

ssh-cp:
	@orb run -m cp-master
ssh-w1:
	@orb run -m worker-1
ssh-w2:
	@orb run -m worker-2
