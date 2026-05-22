# CKA Mock Exam 01

**Time:** 120 Minutes
**Total Score:** 10 Points
**Passing Score:** 7 Points

Please ensure you run `./setup.sh` before starting this exam. You may use the official Kubernetes documentation during the exam.

---

### Question 1: Cluster Architecture (1 point)
Find the names of all nodes in the cluster that are in a `Ready` status. Write their names to the file `/var/tmp/ready-nodes.txt`. Each node name should be on a new line.

### Question 2: Workloads (1 point)
Create a new pod named `nginx-resolver` with the image `nginx` in the `default` namespace.
Expose it internally using a Service named `nginx-resolver-svc` on port 80.

### Question 3: Troubleshooting (1 point)
A deployment named `broken-deploy` in the `alpha` namespace is failing to start because of an invalid image tag.
Fix the deployment by updating its image to `nginx:1.14.3-alpine`. Ensure the deployment pods become ready.

### Question 4: RBAC (1 point)
In the namespace `project-tiger`, create a ServiceAccount named `processor`.
Create a Role named `processor-role` in the same namespace that allows `create` operations on `deployments`.
Bind the Role to the ServiceAccount using a RoleBinding named `processor-binding`.

### Question 5: Networking (1 point)
Create a NetworkPolicy named `deny-all` in the namespace `secure-ns` that denies all incoming (ingress) and outgoing (egress) traffic for all pods in that namespace.

### Question 6: Storage (1 point)
Create a PersistentVolume named `app-data` of capacity `1Gi` and access mode `ReadWriteMany`. Use the `hostPath` volume type with path `/opt/app-data`.
Then, create a PersistentVolumeClaim named `app-data-pvc` requesting `500Mi` with access mode `ReadWriteMany` in the `default` namespace.

### Question 7: Scheduling (1 point)
Deploy a single pod named `high-priority` with the image `redis` in the `default` namespace.
Configure the pod so it can be scheduled on a control-plane node (tolerate the taint `node-role.kubernetes.io/control-plane:NoSchedule` or whatever taint is on the control-plane node).

### Question 8: Configuration (1 point)
Create a ConfigMap named `app-config` in the `default` namespace containing the key-value pair `app=prod`.
Create a pod named `config-pod` using the `nginx` image, and mount this ConfigMap into the pod as a volume at the path `/etc/config`.

### Question 9: Logging (1 point)
There is a pod named `log-generator` running in the `default` namespace.
Extract its logs and save them to the file `/var/tmp/log-generator.txt`.

### Question 10: Ingress (1 point)
There is an existing service named `web-service` in the `default` namespace.
Create an Ingress named `web-ingress` in the `default` namespace that routes traffic for the host `example.com` to `web-service` on port 80.
