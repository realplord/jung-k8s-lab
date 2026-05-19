#!/bin/bash
set -e

echo ">>> Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo ">>> Configuring passwordless sudo for default user..."
echo "$(id -un) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-orbstack-user > /dev/null

echo ">>> Configuring kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo ">>> Setting sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo ">>> Installing containerd..."
sudo apt-get update
sudo apt-get install -y containerd

echo ">>> Configuring containerd to use systemd cgroup..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo ">>> Setting up kubectl bash auto-completion and 'k' alias..."
sudo apt-get install -y bash-completion
for user_home in /root /home/jungeun; do
  if [ -d "$user_home" ]; then
    echo "source <(kubectl completion bash)" | sudo tee -a "$user_home/.bashrc" >/dev/null
    echo "alias k=kubectl" | sudo tee -a "$user_home/.bashrc" >/dev/null
    echo "complete -o default -F __start_kubectl k" | sudo tee -a "$user_home/.bashrc" >/dev/null
  fi
done

echo ">>> Common setup complete."
