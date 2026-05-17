#!/bin/bash
set -e

# Extract local IP
IPADDR=$(hostname -I | awk '{print $1}')

echo ">>> Pre-pulling Kubernetes images (this may take a few minutes)..."
sudo kubeadm config images list | grep -v "Finished" | xargs -I {} -P 4 sudo crictl pull {}

echo ">>> Initializing Kubernetes cluster on ${IPADDR}..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=${IPADDR}

echo ">>> Setting up kubeconfig for $(whoami)..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo ">>> Installing Calico CNI..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/custom-resources.yaml

echo ">>> Generating join command for workers..."
kubeadm token create --print-join-command > join-command.sh
chmod +x join-command.sh

echo ">>> Master setup complete."
