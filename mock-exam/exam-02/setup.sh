#!/bin/bash
echo "Setting up CKA Mock Exam 02..."

# Check if kubectl is available and cluster is running
if ! kubectl get nodes &> /dev/null; then
    echo "Cluster is not available. Please ensure the cluster is running (e.g. via 'make up-ready' in the project root)."
    exit 1
fi

# Detect node names dynamically
if kubectl get node worker-2 &>/dev/null; then
    NODE2="worker-2"
else
    NODE2="worker2"
fi

if kubectl get node worker-1 &>/dev/null; then
    NODE1="worker-1"
else
    NODE1="worker1"
fi

echo "Detected nodes: Node 1 = $NODE1, Node 2 = $NODE2"

# Ensure etcdctl is installed
if ! command -v etcdctl &> /dev/null; then
    echo "etcdctl not found. Installing etcd-client..."
    sudo apt-get update && sudo apt-get install -y etcd-client || echo "Warning: Failed to install etcd-client, please install it manually."
fi

echo "Cleaning up any old resources..."
# Q1: Uncordon Node 2 if it was previously drained
kubectl uncordon "$NODE2" &>/dev/null || true

# Q2: Delete etcd backup if exists
sudo rm -f /var/tmp/etcd-snapshot.db

# Q3: Delete HPA, deployment and production namespace if exists
kubectl delete hpa web-app-hpa -n production &> /dev/null || true
kubectl delete deployment web-app -n production &> /dev/null || true
kubectl delete namespace production &> /dev/null || true

# Q4: Delete app-logger pod if exists
kubectl delete pod app-logger -n default &> /dev/null || true

# Q5: Remove label from Node 1 and delete ssd-pod
kubectl label node "$NODE1" disktype- &> /dev/null || true
kubectl delete pod ssd-pod -n default &> /dev/null || true

# Q6: Delete storage expansion lab resources
kubectl delete pvc pvc-expand -n default &> /dev/null || true
kubectl delete pv pv-expand &> /dev/null || true
kubectl delete sc expandable-sc &> /dev/null || true
rm -rf /opt/pv-expand

# Q7: Delete crashing db-monitor resources
kubectl delete pod db-monitor -n database &> /dev/null || true
kubectl delete namespace database &> /dev/null || true
rm -f /var/tmp/db-error.txt

# Q8: Delete NodePort service and web-backend pod
kubectl delete svc external-web-svc -n default &> /dev/null || true
kubectl delete pod web-backend -n default &> /dev/null || true

# Q9: Delete RBAC resources
kubectl delete clusterrolebinding observer-binding &> /dev/null || true
kubectl delete clusterrole pod-reader &> /dev/null || true
kubectl delete serviceaccount cluster-observer -n kube-system &> /dev/null || true

# Q10: Delete NetworkPolicy and frontend namespace
kubectl delete namespace frontend &> /dev/null || true

echo "--------------------------------------------------"
echo "Setting up resources for new questions..."

echo "Creating namespaces..."
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace database --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace frontend --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying HPA target web-app deployment for Question 3..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
EOF

echo "Deploying crashing database pod db-monitor for Question 7..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: db-monitor
  namespace: database
spec:
  containers:
  - name: db
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      echo "INFO: Starting database monitor service..."
      sleep 2
      echo "WARN: Slow connection detected to primary storage..."
      sleep 2
      echo "FATAL: database connection refused on port 5432 - authorization failed"
      sleep 1
      exit 1
  restartPolicy: OnFailure
EOF

echo "Deploying web-backend pod for Question 8..."
kubectl run web-backend --image=nginx:alpine -n default --labels="app=web-backend" --dry-run=client -o yaml | kubectl apply -f -

echo "Setup complete. You may begin CKA Mock Exam 02!"
