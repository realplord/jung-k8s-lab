#!/bin/bash
set -e

echo "=== Solving Question 1: Cluster Architecture ==="
# Find Ready nodes and save to /var/tmp/ready-nodes.txt
kubectl get nodes --no-headers | awk '$2=="Ready" {print $1}' > /var/tmp/ready-nodes.txt
echo "Ready nodes saved to /var/tmp/ready-nodes.txt:"
cat /var/tmp/ready-nodes.txt

echo "=== Solving Question 2: Workloads ==="
# Create nginx-resolver pod and expose it as a Service
kubectl run nginx-resolver --image=nginx -n default
kubectl expose pod nginx-resolver --name=nginx-resolver-svc --port=80 -n default

echo "=== Solving Question 3: Troubleshooting ==="
# Update image of broken-deploy to nginx:1.14.3-alpine and ensure ready
kubectl set image deployment/broken-deploy *=nginx:1.14.3-alpine -n alpha

echo "=== Solving Question 4: RBAC ==="
# Create ServiceAccount, Role, and RoleBinding in project-tiger
kubectl create serviceaccount processor -n project-tiger
kubectl create role processor-role --verb=create --resource=deployments -n project-tiger
kubectl create rolebinding processor-binding --role=processor-role --serviceaccount=project-tiger:processor -n project-tiger

echo "=== Solving Question 5: Networking ==="
# Create deny-all NetworkPolicy in secure-ns namespace
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: secure-ns
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

echo "=== Solving Question 6: Storage ==="
# Create PV and PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: app-data
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: /opt/app-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 500Mi
EOF

echo "=== Solving Question 7: Scheduling ==="
# Deploy a pod named high-priority tolerating control-plane taint
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: high-priority
  namespace: default
spec:
  containers:
  - name: redis
    image: redis
  tolerations:
  - key: "node-role.kubernetes.io/control-plane"
    operator: "Exists"
    effect: "NoSchedule"
EOF

echo "=== Solving Question 8: Configuration ==="
# Create ConfigMap and mount it to config-pod at /etc/config
kubectl create configmap app-config --from-literal=app=prod -n default
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
EOF

echo "=== Solving Question 9: Logging ==="
# Extract logs of log-generator to /var/tmp/log-generator.txt
kubectl logs log-generator -n default > /var/tmp/log-generator.txt
echo "Logs extracted successfully."

echo "=== Solving Question 10: Ingress ==="
# Create Ingress for web-service on example.com
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: default
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
EOF

echo "=== All questions solved! ==="
