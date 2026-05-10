#!/bin/bash
set -e

# Define Kubernetes version
K8S_VERSION="1.30"

echo ">>> Installing Kubernetes dependencies..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

echo ">>> Adding Kubernetes APT repository..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo ">>> Installing kubelet, kubeadm, kubectl..."
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo ">>> Configuring kubectl aliases and completion..."
{
  echo 'source <(kubectl completion bash)'
  echo 'alias k=kubectl'
  echo 'complete -o default -F __start_kubectl k'
} >> ~/.bashrc

echo ">>> Kubernetes installation complete."
