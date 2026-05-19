#!/bin/bash
set -e

# Define nodes for Exam 2
EXAM2_NODES=("control" "worker1" "worker2")
EXAM2_WORKERS=("worker1" "worker2")

# 1. Ensure the base pre-baked image exists
bash scripts/prepare-exam2-base.sh

# Reset sander-cka repository to discard any previous host-side modifications
if [ -d "sander-cka" ]; then
  echo ">>> Resetting CKA repository to pristine defaults..."
  (cd sander-cka && git checkout -- .)
fi

echo ">>> Instantly provisioning Exam 2 cluster nodes via OrbStack clones..."
for node in "${EXAM2_NODES[@]}"; do
  # Delete existing container if it is present to guarantee a fresh, clean state
  if orb list | grep -q "${node}"; then
    echo "Deleting existing machine ${node}..."
    orb delete -f "${node}" 2>/dev/null || true
  fi
  
  echo "Cloning ${node} from 'exam2-base'..."
  orb clone exam2-base "${node}"
  orb start "${node}"
done

echo ">>> Configuring dynamic hostname resolution..."
bash scripts/setup-hosts.sh "${EXAM2_NODES[@]}"

# 2. Set up passwordless SSH from control to all nodes
echo ">>> Setting up passwordless SSH keys from control plane to all nodes..."
# Generate SSH key on control if it doesn't exist
orb run -m control bash -c '[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa'
PUB_KEY=$(orb run -m control bash -c 'cat ~/.ssh/id_rsa.pub')

# Authorize the key on all nodes to allow passwordless ssh
for node in "${EXAM2_NODES[@]}"; do
  echo "Authorizing control SSH key on ${node}..."
  echo "$PUB_KEY" | orb run -m "$node" bash -c '
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    read KEY
    if ! grep -q "$KEY" ~/.ssh/authorized_keys 2>/dev/null; then
      echo "$KEY" >> ~/.ssh/authorized_keys
    fi
    chmod 600 ~/.ssh/authorized_keys
  '
done

# 3. Initialize Master Node
echo ">>> Initializing Control Plane Node..."
orb run -m control bash scripts/master.sh || exit 1

# 4. Join Workers
echo ">>> Joining Workers to the cluster..."
for worker in "${EXAM2_WORKERS[@]}"; do
  echo "Joining ${worker}..."
  orb run -m "${worker}" sudo sh ./join-command.sh || exit 1
done

# Clean up host-side join-command.sh
rm -f join-command.sh

# 5. Sync Kubeconfig
echo ">>> Syncing kubeconfig to all nodes..."
orb run -m control bash -c "sudo cp /etc/kubernetes/admin.conf ~/.kube/config && sudo chown \$(id -u):\$(id -g) ~/.kube/config && cat ~/.kube/config" > .kubeconfig-temp
for node in "${EXAM2_NODES[@]}"; do
  echo "Syncing config to ${node}..."
  orb run -m "${node}" bash -c "mkdir -p ~/.kube && cat > ~/.kube/config" < .kubeconfig-temp || exit 1
done
rm -f .kubeconfig-temp

# 6. Install Helm
echo ">>> Installing Helm on control plane..."
orb run -m control bash scripts/helm-install.sh || exit 1

# 7. Install Gateway API and Envoy Gateway
echo ">>> Installing Gateway API and Envoy Gateway on control plane..."
orb run -m control bash scripts/gateway-install.sh || exit 1

# 8. Prepare lab scripts and grading symlinks
echo ">>> Preparing lab scripts and links on control..."
orb run -m control bash -c "chmod +x scripts/*.sh"
orb run -m control bash -c "mkdir -p ~/labs && ln -sf \$(pwd)/scripts/etcd-backup.sh ~/labs/etcd-backup.sh"
orb run -m control bash -c "ln -sf \$(pwd)/scripts/etcd-restore.sh ~/labs/etcd-restore.sh"
orb run -m control bash -c "ln -sf \$(pwd)/labs/netpol-lab.yaml ~/labs/netpol-lab.yaml"
orb run -m control bash -c "ln -sf \$(pwd)/sander-cka/exam2-grade.sh ~/labs/exam2-grade.sh"
orb run -m control bash -c "ln -sf \$(pwd)/sander-cka/labs ~/labs/labs"

echo ">>> Exam 2 cluster is successfully provisioned and ready for CKA practice!"
echo ">>> Control Plane Node: control"
echo ">>> Worker Nodes: worker1, worker2"
echo ">>> Run 'make ssh-exam2-c' to access the control plane node."
