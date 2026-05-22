# CKA Mock Exam 01 Answers & Solutions

This guide provides the complete, step-by-step solution for all 10 questions of CKA Mock Exam 01.

---

### Question 1: Cluster Architecture (1 point)
**Task:** Find the names of all nodes in the cluster that are in a `Ready` status and write their names to `/var/tmp/ready-nodes.txt`.

#### Command Solution:
```bash
kubectl get nodes --no-headers | awk '$2=="Ready" {print $1}' > /var/tmp/ready-nodes.txt
```

#### Verification:
```bash
cat /var/tmp/ready-nodes.txt
```

---

### Question 2: Workloads (1 point)
**Task:** Create a new pod named `nginx-resolver` with the image `nginx` in the `default` namespace, and expose it internally using a Service named `nginx-resolver-svc` on port 80.

#### Command Solution:
```bash
# 1. Create the pod
kubectl run nginx-resolver --image=nginx -n default

# 2. Expose the pod as a service
kubectl expose pod nginx-resolver --name=nginx-resolver-svc --port=80 -n default
```

#### Verification:
```bash
kubectl get pod nginx-resolver
kubectl get svc nginx-resolver-svc
```

---

### Question 3: Troubleshooting (1 point)
**Task:** Fix a deployment named `broken-deploy` in the `alpha` namespace which fails to start because of an invalid image tag. Update its image to `nginx:1.14.3-alpine`.

#### Command Solution:
```bash
kubectl set image deployment/broken-deploy *=nginx:1.14.3-alpine -n alpha
```

#### Verification:
```bash
kubectl rollout status deployment/broken-deploy -n alpha
```

---

### Question 4: RBAC (1 point)
**Task:** Create a ServiceAccount named `processor`, a Role named `processor-role` allowing `create` operations on `deployments`, and bind them using a RoleBinding named `processor-binding` in the `project-tiger` namespace.

#### Command Solution:
```bash
# 1. Create ServiceAccount
kubectl create serviceaccount processor -n project-tiger

# 2. Create Role
kubectl create role processor-role --verb=create --resource=deployments -n project-tiger

# 3. Create RoleBinding
kubectl create rolebinding processor-binding --role=processor-role --serviceaccount=project-tiger:processor -n project-tiger
```

#### Verification:
```bash
kubectl auth can-i create deployments --as=system:serviceaccount:project-tiger:processor -n project-tiger
```

---

### Question 5: Networking (1 point)
**Task:** Create a NetworkPolicy named `deny-all` in the namespace `secure-ns` that denies all incoming (ingress) and outgoing (egress) traffic for all pods in that namespace.

#### Declarative Solution:
Apply the following YAML using `kubectl apply -f`:

```yaml
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
```

#### Verification:
```bash
kubectl describe networkpolicy deny-all -n secure-ns
```

---

### Question 6: Storage (1 point)
**Task:** Create a PersistentVolume named `app-data` (1Gi, hostPath `/opt/app-data`, ReadWriteMany) and a PersistentVolumeClaim named `app-data-pvc` (500Mi, ReadWriteMany) in the `default` namespace.

#### Declarative Solution:
Apply the following YAML:

```yaml
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
```

#### Verification:
```bash
kubectl get pv app-data
kubectl get pvc app-data-pvc
```

---

### Question 7: Scheduling (1 point)
**Task:** Deploy a single pod named `high-priority` with the image `redis` in the `default` namespace that can be scheduled on a control-plane node (tolerate the `node-role.kubernetes.io/control-plane:NoSchedule` taint).

#### Declarative Solution:
Apply the following YAML:

```yaml
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
```

#### Verification:
```bash
kubectl get pod high-priority -o wide
```

---

### Question 8: Configuration (1 point)
**Task:** Create a ConfigMap named `app-config` with the pair `app=prod` in the `default` namespace. Create a pod named `config-pod` using the `nginx` image and mount the ConfigMap into the pod as a volume at `/etc/config`.

#### Declarative Solution:
Apply the following YAML:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
data:
  app: prod
---
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
```

#### Verification:
```bash
kubectl exec config-pod -- cat /etc/config/app
```

---

### Question 9: Logging (1 point)
**Task:** Extract the logs of the pod `log-generator` running in the `default` namespace and save them to `/var/tmp/log-generator.txt`.

#### Command Solution:
```bash
kubectl logs log-generator -n default > /var/tmp/log-generator.txt
```

#### Verification:
```bash
cat /var/tmp/log-generator.txt
```

---

### Question 10: Ingress (1 point)
**Task:** Create an Ingress named `web-ingress` in the `default` namespace that routes traffic for the host `example.com` to the existing service `web-service` on port 80.

#### Declarative Solution:
Apply the following YAML:

```yaml
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
```

#### Verification:
```bash
kubectl describe ingress web-ingress
```
