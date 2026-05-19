#!/bin/bash
set -e

BASE_NAME="exam2-base"

# Check if base image already exists
if orb list | grep -q "${BASE_NAME}"; then
  echo ">>> Base image '${BASE_NAME}' already exists. Reusing it for instant provisioning!"
  exit 0
fi

echo ">>> Base image '${BASE_NAME}' not found. Building it from scratch (this only runs ONCE)..."

# 1. Create and start base machine
orb create ubuntu:noble "${BASE_NAME}" 2>/dev/null || true
orb start "${BASE_NAME}"

# Wait for network and DNS to be fully ready inside base machine
echo ">>> Waiting for network and DNS to be fully ready inside base machine..."
for i in {1..15}; do
  if orb run -m "${BASE_NAME}" curl -s -I https://github.com >/dev/null; then
    echo ">>> Network is fully active!"
    break
  fi
  echo ">>> Waiting for network..."
  sleep 2
done

# 2. Run common setup (passwordless sudo, packages, cgroups)
echo ">>> Configuring common environment on base machine..."
orb run -m "${BASE_NAME}" bash scripts/common.sh

# 3. Clone and patch sandervanvugt/cka repository if not exists
echo ">>> Fetching CKA tools repository..."
if [ ! -d "sander-cka" ]; then
  git clone https://github.com/sandervanvugt/cka sander-cka
fi

# Reset sander-cka repository to discard any previous host-side modifications
(cd sander-cka && git checkout -- .)

# Apply our patches to setup-kubetools-previousversion.sh to make it non-interactive and robust
perl -pi -e 's/MYOS=\$\(hostnamectl.*/MYOS=Ubuntu/g' sander-cka/setup-kubetools-previousversion.sh
perl -pi -e 's/apt-transport-https curl/apt-transport-https ca-certificates curl gpg gnupg/g' sander-cka/setup-kubetools-previousversion.sh
perl -pi -e 's/gpg --dearmor/gpg --yes --dearmor/g' sander-cka/setup-kubetools-previousversion.sh

# Force MYOS=Ubuntu in Sander's scripts to make OS detection 100% reliable inside minimal containers
perl -pi -e 's/MYOS=\$\(hostnamectl.*/MYOS=Ubuntu/g' sander-cka/setup-container.sh

# Ensure that /tmp/container.txt is touched so setup-kubetools-previousversion.sh runs successfully
orb run -m "${BASE_NAME}" touch /tmp/container.txt

# 4. Install container runtime (CRI)
echo ">>> Pre-installing Container Runtime (CRI)..."
orb run -m "${BASE_NAME}" bash -c "cd sander-cka && bash setup-container.sh"

# 5. Install Kubetools of the previous version
echo ">>> Pre-installing Kubernetes tools (previous version)..."
orb run -m "${BASE_NAME}" bash -c "cd sander-cka && sudo bash setup-kubetools-previousversion.sh"

# Explicitly install cri-tools because of upstream packaging bug in v1.35.5-1.1
echo ">>> Explicitly installing cri-tools..."
orb run -m "${BASE_NAME}" sudo apt-get install -y cri-tools

# 6. Pre-install required pre-flight tools (conntrack, socat)
echo ">>> Restoring clean Containerd configuration and pre-flight tools..."
orb run -m "${BASE_NAME}" sudo apt-get install -y conntrack socat
orb run -m "${BASE_NAME}" sudo apt-get install --reinstall -y containerd
orb run -m "${BASE_NAME}" sudo rm -f /usr/local/bin/containerd /usr/local/bin/containerd-shim-runc-v2 /usr/local/bin/containerd-stress /usr/local/bin/ctr /usr/local/sbin/runc
orb run -m "${BASE_NAME}" bash -c "sudo mkdir -p /etc/containerd && /usr/bin/containerd config default | sudo tee /etc/containerd/config.toml > /dev/null"
orb run -m "${BASE_NAME}" sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
orb run -m "${BASE_NAME}" sudo systemctl daemon-reload
orb run -m "${BASE_NAME}" sudo systemctl restart containerd

# 7. Stop the base machine to keep it static and safe for cloning
echo ">>> Stopping base machine..."
orb stop "${BASE_NAME}"

echo ">>> Base image '${BASE_NAME}' successfully created and optimized!"
