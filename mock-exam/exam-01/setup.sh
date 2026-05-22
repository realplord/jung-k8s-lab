#!/bin/bash
echo "Setting up CKA Mock Exam 01..."

# Check if kubectl is available and cluster is running
if ! kubectl get nodes &> /dev/null; then
    echo "Cluster is not available. Please ensure the cluster is running (e.g. via 'make up-ready' in the project root)."
    exit 1
fi

echo "Creating namespaces..."
kubectl create namespace alpha --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace project-tiger --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace secure-ns --dry-run=client -o yaml | kubectl apply -f -

echo "Pre-pulling and tagging nginx:1.14.3-alpine image on all nodes..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: image-preparer
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: image-preparer
  template:
    metadata:
      labels:
        name: image-preparer
    spec:
      hostPID: true
      hostNetwork: true
      tolerations:
      - operator: Exists
        effect: NoSchedule
      - operator: Exists
        effect: NoExecute
      initContainers:
      - name: prepare-image
        image: alpine
        securityContext:
          privileged: true
        command:
        - nsenter
        - --target
        - "1"
        - --mount
        - --uts
        - --ipc
        - --net
        - --
        - sh
        - -c
        - |
          ctr -n k8s.io images pull docker.io/library/nginx:alpine
          ctr -n k8s.io images tag docker.io/library/nginx:alpine docker.io/library/nginx:1.14.3-alpine
      containers:
      - name: sleep
        image: alpine
        command: ["sleep", "3600"]
EOF

echo "Waiting for image pre-pull to complete across all nodes..."
kubectl rollout status daemonset/image-preparer -n kube-system

echo "Cleaning up temporary image preparer DaemonSet..."
kubectl delete daemonset image-preparer -n kube-system

echo "Creating broken deployment for Question 3..."
kubectl create deployment broken-deploy --image=nginx:1.14.3-alpine-xyz -n alpha --dry-run=client -o yaml | kubectl apply -f -

echo "Creating log-generator pod for Question 9..."
kubectl run log-generator --image=busybox -n default --dry-run=client -o yaml -- /bin/sh -c 'while true; do echo "INFO: Writing log line..."; sleep 5; done' | kubectl apply -f -

echo "Creating web-service for Question 10..."
kubectl create service clusterip web-service --tcp=80:80 -n default --dry-run=client -o yaml | kubectl apply -f -

echo "Setup complete. You may begin the exam!"
