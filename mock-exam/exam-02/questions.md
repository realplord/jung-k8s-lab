# CKA Mock Exam 02

**Time:** 120 Minutes
**Total Score:** 10 Points
**Passing Score:** 7 Points

Please ensure you run `./setup.sh` before starting this exam. You may use the official Kubernetes documentation during the exam.

---

### Question 1: Maintenance / Node Drain (1 point)
Drain the node `worker2` to prepare it for maintenance. Ensure all pods are evicted safely, ignoring DaemonSets and local data (emptyDir volume) if necessary.

### Question 2: Cluster Configuration / ETCD Backup (1 point)
Take a snapshot backup of the etcd database running on the control plane node. Save the backup at `/var/tmp/etcd-snapshot.db`.

### Question 3: Workloads / Horizontal Pod Autoscaling (HPA) (1 point)
Create a HorizontalPodAutoscaler named `web-app-hpa` for the existing deployment named `web-app` in the `production` namespace. The HPA should scale between 2 and 6 replicas, targeting a CPU utilization of 60%.

### Question 4: Troubleshooting / Sidecar Logging (1 point)
Create a multi-container pod named `app-logger` in the `default` namespace. 
- The main container should be named `app` running the image `busybox` and writing a new timestamp line to `/var/log/app.log` every 5 seconds.
- The sidecar container should be named `sidecar` running the image `busybox` and continuously streaming the contents of `/var/log/app.log` to its standard output.
Use an `emptyDir` volume for the shared log directory.

### Question 5: Scheduling / Node Selector & Labels (1 point)
Label the node `worker1` with `disktype=ssd`. 
Then, create a pod named `ssd-pod` running `nginx` in the `default` namespace that is scheduled only on nodes labeled with `disktype=ssd`.

### Question 6: Storage / Volume Expansion (1 point)
Create a StorageClass named `expandable-sc` with `allowVolumeExpansion` set to `true`.
Create a PersistentVolume named `pv-expand` of capacity `1Gi`, access mode `ReadWriteOnce`, and using this StorageClass. Use the `hostPath` volume type with path `/opt/pv-expand`.
Create a PersistentVolumeClaim named `pvc-expand` requesting `100Mi` with access mode `ReadWriteOnce` in the `default` namespace.
Finally, expand the PVC size to `200Mi`.

### Question 7: Troubleshooting / Crashing Pods (1 point)
A pod named `db-monitor` in the `database` namespace is crashing. 
Diagnose the issue, find the exact log line containing the word `FATAL` in the container logs, and write it to `/var/tmp/db-error.txt`.

### Question 8: Services & Endpoints / NodePort (1 point)
Create a Service of type `NodePort` named `external-web-svc` in the `default` namespace. 
It should expose the existing pod `web-backend` on port `80`, routing to targetPort `80`, with a nodePort of `32080`.

### Question 9: RBAC / ClusterRole Binding (1 point)
Create a ClusterRole named `pod-reader` that allows `get`, `list`, and `watch` operations on `pods`. 
Create a ServiceAccount named `cluster-observer` in the `kube-system` namespace. 
Bind the ClusterRole to the ServiceAccount globally using a ClusterRoleBinding named `observer-binding`.

### Question 10: Networking / Cross-Namespace Network Policies (1 point)
Create a NetworkPolicy named `allow-db-access` in the `database` namespace. 
The policy should allow incoming (ingress) traffic on port `5432` only from pods in the `frontend` namespace that have the label `role=frontend`. 
All other ingress traffic to pods in the `database` namespace should be blocked.
