# CKA Mock Exam 02 Answers & Solutions

This guide provides the complete, step-by-step solution for all 10 questions of CKA Mock Exam 02.

---

### Question 1: Maintenance / Node Drain (1 point)
**Task:** Drain the node `worker-2` to prepare it for maintenance. Ignore DaemonSets and local data if necessary.

#### Command Solution:
```bash
# Note: Node name may be worker-2 or worker2 depending on the topology.
kubectl drain worker-2 --ignore-daemonsets --delete-emptydir-data --force
```

#### Verification:
```bash
kubectl get nodes
```

---

### Question 2: Cluster Configuration / ETCD Backup (1 point)
**Task:** Take a snapshot backup of the etcd database running on the control plane node and save it at `/var/tmp/etcd-snapshot.db`.

#### Command Solution:
```bash
sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  snapshot save /var/tmp/etcd-snapshot.db
```

#### Verification:
```bash
sudo ETCDCTL_API=3 etcdctl --write-out=table snapshot status /var/tmp/etcd-snapshot.db
```

---

### Question 3: Workloads / Horizontal Pod Autoscaling (HPA) (1 point)
**Task:** Create a HorizontalPodAutoscaler named `web-app-hpa` for the existing deployment named `web-app` in the `production` namespace. Scale between 2 and 6 replicas, targeting a CPU utilization of 60%.

#### Declarative Solution:
Apply the following HPA manifest using `kubectl apply -f`:

```yaml
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
```

#### Verification:
```bash
kubectl get hpa web-app-hpa -n production
```

---

### Question 4: Troubleshooting / Sidecar Logging (1 point)
**Task:** Create a multi-container pod named `app-logger` in the `default` namespace. The main container `app` should write logs to `/var/log/app.log` every 5 seconds, and the `sidecar` container should stream the log to stdout.

#### Declarative Solution:
Apply the following YAML:

```yaml
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
        echo "$(date) - Application log message" >> /var/log/app.log
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
```

#### Verification:
```bash
kubectl logs app-logger -n default -c sidecar
```

---

### Question 5: Scheduling / Node Selector & Labels (1 point)
**Task:** Label the node `worker-1` with `disktype=ssd`. Create a pod named `ssd-pod` running `nginx` that is scheduled only on nodes labeled with `disktype=ssd`.

#### Command & Declarative Solution:
```bash
# 1. Label the node
kubectl label node worker-1 disktype=ssd --overwrite
```

Apply the following pod manifest:
```yaml
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
```

#### Verification:
```bash
kubectl get pod ssd-pod -o wide
```

---

### Question 6: Storage / Volume Expansion (1 point)
**Task:** Create a StorageClass `expandable-sc` with volume expansion enabled. Create a PersistentVolume `pv-expand` (1Gi, hostPath `/opt/pv-expand`). Create a PVC `pvc-expand` (100Mi) and then expand it to `200Mi`.

#### Declarative Solution:
Apply the following manifest:

```yaml
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
```

Wait until the PVC is bound, and then execute the expansion patch:
```bash
kubectl patch pvc pvc-expand -n default -p '{"spec":{"resources":{"requests":{"storage":"200Mi"}}}}'
```

#### Verification:
```bash
kubectl get pvc pvc-expand
```

---

### Question 7: Troubleshooting / Crashing Pods (1 point)
**Task:** Extract the `FATAL` log line from the crashing `db-monitor` pod in the `database` namespace and write it to `/var/tmp/db-error.txt`.

#### Command Solution:
```bash
kubectl logs db-monitor -n database 2>&1 | grep FATAL > /var/tmp/db-error.txt
```

#### Verification:
```bash
cat /var/tmp/db-error.txt
```

---

### Question 8: Services & Endpoints / NodePort (1 point)
**Task:** Expose the existing pod `web-backend` externally on port 80 via a NodePort Service named `external-web-svc` with a nodePort of `32080`.

#### Declarative Solution:
Apply the following YAML:

```yaml
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
```

#### Verification:
```bash
kubectl get svc external-web-svc
```

---

### Question 9: RBAC / ClusterRole Binding (1 point)
**Task:** Create a ClusterRole named `pod-reader` that allows `get`, `list`, and `watch` on `pods`. Create a ServiceAccount named `cluster-observer` in the `kube-system` namespace. Bind them globally with a ClusterRoleBinding named `observer-binding`.

#### Declarative Solution:
Apply the following YAML:

```yaml
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
```

#### Verification:
```bash
kubectl auth can-i list pods --as=system:serviceaccount:kube-system:cluster-observer --all-namespaces
```

---

### Question 10: Networking / Network Policies (1 point)
**Task:** Create a NetworkPolicy named `allow-db-access` in the `database` namespace that allows ingress on port `5432` only from pods in the namespace `frontend` that have the label `role=frontend`. Block all other ingress traffic to the namespace.

#### Declarative & Command Solution:
Ensure the `frontend` namespace is labeled:
```bash
kubectl label namespace frontend name=frontend --overwrite
```

Apply the NetworkPolicy:
```yaml
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
```

#### Verification:
```bash
kubectl describe networkpolicy allow-db-access -n database
```
