#!/bin/bash
set -e

echo ">>> Installing Gateway API..."
kubectl apply --server-side=true -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml

echo ">>> Installing Envoy Gateway..."
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.7.1 \
  -n envoy-gateway-system \
  --create-namespace

echo ">>> Defining Envoy GatewayClass..."
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy-gateway
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
  description: "Default Envoy Gateway Class for local practice"
EOF

echo ">>> Verifying GatewayClass..."
kubectl get gatewayclass envoy-gateway

echo ">>> Gateway API and Envoy Gateway installation complete."
