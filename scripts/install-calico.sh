#!/bin/bash
set -e

echo ">>> Starting Robust Calico CNI Installation..."

# 1. Wait for Kubernetes API to be fully responsive
echo ">>> Checking API server health..."
until kubectl get nodes &>/dev/null; do
  echo "Waiting for API server to respond..."
  sleep 3
done

# 2. Patch kubeadm-config ConfigMap if podSubnet is missing
echo ">>> Checking kubeadm podSubnet configuration..."
if kubectl get cm -n kube-system kubeadm-config -o yaml | grep -q "podSubnet"; then
  echo ">>> Active podSubnet detected in ConfigMap."
else
  echo ">>> WARNING: No podSubnet found in ConfigMap. Patching ConfigMap with safe subnet 172.16.0.0/16 to satisfy Tigera Operator requirements..."
  kubectl get cm -n kube-system kubeadm-config -o yaml | python3 -c "
import sys, yaml
config = yaml.safe_load(sys.stdin)
cluster_config = yaml.safe_load(config['data']['ClusterConfiguration'])
if 'networking' not in cluster_config:
    cluster_config['networking'] = {}
cluster_config['networking']['podSubnet'] = '172.16.0.0/16'
config['data']['ClusterConfiguration'] = yaml.dump(cluster_config)
print(yaml.dump(config))
" | kubectl apply -f -
fi

# 3. Apply Tigera Calico Operator
echo ">>> Applying Tigera Operator..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml || true

echo ">>> Waiting for Tigera Operator CRDs to be established..."
until kubectl get crd installations.operator.tigera.io &>/dev/null; do
  sleep 1
done

# 4. Generate and apply custom resources with explicit LXC interface auto-detection
echo ">>> Applying Calico Custom Resources with 192.168.0.0/16 IPPool and LXC interface filters..."
cat << 'EOF' > calico-custom-resources-temp.yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
    nodeAddressAutodetectionV4:
      interface: eth0.*
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF

kubectl apply -f calico-custom-resources-temp.yaml
rm -f calico-custom-resources-temp.yaml

echo ">>> Calico CNI successfully configured!"
echo ">>> Current pods status:"
kubectl get pods -A
