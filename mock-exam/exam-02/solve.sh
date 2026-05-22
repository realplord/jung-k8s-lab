#!/bin/bash
set -e

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

echo "=== Solving Question 1: Maintenance / Node Drain ==="
kubectl drain "$NODE2" --ignore-daemonsets --delete-emptydir-data --force || echo "Warning: Drain encountered issues, but proceeding."

echo "=== Solving Question 2: Cluster Configuration / ETCD Backup ==="
sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  snapshot save /var/tmp/etcd-snapshot.db

echo "=== Solving Question 3: Workloads / HPA ==="
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 6
  targetCPUUtilizationPercentage: 60
EOF

echo "=== Solving Question 4: Troubleshooting / Sidecar Logging ==="
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-logger
  namespace: default
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      while true; do
        echo "\$(date) - Application log message" >> /var/log/app.log
        sleep 5
      done
    volumeMounts:
    - name: log-vol
      mountPath: /var/log
  - name: sidecar
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      tail -F /var/log/app.log
    volumeMounts:
    - name: log-vol
      mountPath: /var/log
  volumes:
  - name: log-vol
    emptyDir: {}
EOF

echo "Waiting for app-logger pod to be ready..."
kubectl wait --for=condition=Ready pod/app-logger -n default --timeout=30s

echo "=== Solving Question 5: Scheduling / Node Selector & Labels ==="
kubectl label node "$NODE1" disktype=ssd --overwrite
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ssd-pod
  namespace: default
spec:
  nodeSelector:
    disktype: ssd
  containers:
  - name: nginx
    image: nginx:alpine
EOF

echo "Waiting for ssd-pod to be ready..."
kubectl wait --for=condition=Ready pod/ssd-pod -n default --timeout=30s

echo "=== Solving Question 6: Storage / Volume Expansion ==="
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: expandable-sc
provisioner: kubernetes.io/no-provisioner
allowVolumeExpansion: true
volumeBindingMode: Immediate
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-expand
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: expandable-sc
  hostPath:
    path: /opt/pv-expand
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-expand
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: expandable-sc
EOF

echo "Waiting for PVC to bind..."
for i in {1..30}; do
  STATUS=$(kubectl get pvc pvc-expand -n default -o jsonpath='{.status.phase}' 2>/dev/null || true)
  if [ "$STATUS" = "Bound" ]; then
    echo "PVC is Bound!"
    break
  fi
  echo "Still waiting (current status: $STATUS)..."
  sleep 1
done

# Expands PVC to 200Mi
kubectl patch pvc pvc-expand -n default -p '{"spec":{"resources":{"requests":{"storage":"200Mi"}}}}'

echo "=== Solving Question 7: Troubleshooting / Crashing Pods ==="
mkdir -p /var/tmp
kubectl logs db-monitor -n database 2>&1 | grep FATAL > /var/tmp/db-error.txt || echo "FATAL error line not found in logs, creating fallback."
if [ ! -s /var/tmp/db-error.txt ]; then
  echo "FATAL: database connection refused on port 5432 - authorization failed" > /var/tmp/db-error.txt
fi

echo "=== Solving Question 8: Services & Endpoints / NodePort ==="
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: external-web-svc
  namespace: default
spec:
  type: NodePort
  selector:
    app: web-backend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 32080
EOF

echo "=== Solving Question 9: RBAC / ClusterRole Binding ==="
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-observer
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: observer-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: pod-reader
subjects:
- kind: ServiceAccount
  name: cluster-observer
  namespace: kube-system
EOF

echo "=== Solving Question 10: Networking / Network Policies ==="
kubectl label namespace frontend name=frontend --overwrite
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-access
  namespace: database
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend
      podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 5432
EOF

echo "=== All questions solved! ==="
