#!/bin/bash
SCORE=0
TOTAL=10

echo "Grading CKA Mock Exam 02..."
echo "=============================="

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

# Q1: Maintenance / Node Drain
UNSCHED=$(kubectl get node "$NODE2" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$UNSCHED" == "true" ]; then
    echo "[PASS] Q1: Maintenance / Node Drain"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q1: Maintenance / Node Drain ($NODE2 is not cordoned/drained)"
fi

# Q2: Cluster Configuration / ETCD Backup
if [ -f /var/tmp/etcd-snapshot.db ] && [ -s /var/tmp/etcd-snapshot.db ]; then
    echo "[PASS] Q2: Cluster Configuration / ETCD Backup"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q2: Cluster Configuration / ETCD Backup (/var/tmp/etcd-snapshot.db does not exist or is empty)"
fi

# Q3: Workloads / HPA
HPA_NAME=$(kubectl get hpa web-app-hpa -n production -o jsonpath='{.metadata.name}' 2>/dev/null)
HPA_MIN=$(kubectl get hpa web-app-hpa -n production -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
HPA_MAX=$(kubectl get hpa web-app-hpa -n production -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
HPA_TARGET=$(kubectl get hpa web-app-hpa -n production -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null)

if [ "$HPA_NAME" == "web-app-hpa" ] && [ "$HPA_MIN" -eq 2 ] 2>/dev/null && [ "$HPA_MAX" -eq 6 ] 2>/dev/null && [ "$HPA_TARGET" == "web-app" ]; then
    echo "[PASS] Q3: Workloads / HPA"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q3: Workloads / HPA (HPA missing or incorrectly configured)"
fi

# Q4: Troubleshooting / Sidecar Logging
POD_PHASE=$(kubectl get pod app-logger -n default -o jsonpath='{.status.phase}' 2>/dev/null)
CONTAINER_COUNT=$(kubectl get pod app-logger -n default -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}' 2>/dev/null | wc -l | tr -d ' ')
if [ "$POD_PHASE" == "Running" ] && [ "$CONTAINER_COUNT" -eq 2 ] 2>/dev/null; then
    echo "[PASS] Q4: Troubleshooting / Sidecar Logging"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q4: Troubleshooting / Sidecar Logging (app-logger pod not running or does not have exactly 2 containers)"
fi

# Q5: Scheduling / Node Selector
NODE_LABEL=$(kubectl get node "$NODE1" -o jsonpath='{.metadata.labels.disktype}' 2>/dev/null)
POD_SELECTOR=$(kubectl get pod ssd-pod -n default -o jsonpath='{.spec.nodeSelector.disktype}' 2>/dev/null)
if [ "$NODE_LABEL" == "ssd" ] && [ "$POD_SELECTOR" == "ssd" ]; then
    echo "[PASS] Q5: Scheduling / Node Selector"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q5: Scheduling / Node Selector ($NODE1 label or pod nodeSelector is missing/incorrect)"
fi

# Q6: Storage / Volume Expansion
SC_EXPAND=$(kubectl get sc expandable-sc -o jsonpath='{.allowVolumeExpansion}' 2>/dev/null)
PVC_SIZE=$(kubectl get pvc pvc-expand -n default -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null)
if [ "$SC_EXPAND" == "true" ] && [[ "$PVC_SIZE" == *"200Mi"* ]]; then
    echo "[PASS] Q6: Storage / Volume Expansion"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q6: Storage / Volume Expansion (StorageClass allowVolumeExpansion not true or PVC is not 200Mi)"
fi

# Q7: Troubleshooting / Crashing Pods
if [ -f /var/tmp/db-error.txt ] && grep -q "FATAL" /var/tmp/db-error.txt 2>/dev/null; then
    echo "[PASS] Q7: Troubleshooting / Crashing Pods"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q7: Troubleshooting / Crashing Pods (/var/tmp/db-error.txt does not contain the FATAL error log)"
fi

# Q8: Services & Endpoints / NodePort
SVC_TYPE=$(kubectl get svc external-web-svc -n default -o jsonpath='{.spec.type}' 2>/dev/null)
SVC_PORT=$(kubectl get svc external-web-svc -n default -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ "$SVC_TYPE" == "NodePort" ] && [ "$SVC_PORT" -eq 32080 ] 2>/dev/null; then
    echo "[PASS] Q8: Services & Endpoints / NodePort"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q8: Services & Endpoints / NodePort (service missing, not NodePort, or incorrect nodePort)"
fi

# Q9: RBAC / ClusterRole Binding
CR_ROLE=$(kubectl get clusterrolebinding observer-binding -o jsonpath='{.roleRef.name}' 2>/dev/null)
CR_SUB_NAME=$(kubectl get clusterrolebinding observer-binding -o jsonpath='{.subjects[0].name}' 2>/dev/null)
CR_SUB_NS=$(kubectl get clusterrolebinding observer-binding -o jsonpath='{.subjects[0].namespace}' 2>/dev/null)
if [ "$CR_ROLE" == "pod-reader" ] && [ "$CR_SUB_NAME" == "cluster-observer" ] && [ "$CR_SUB_NS" == "kube-system" ]; then
    echo "[PASS] Q9: RBAC / ClusterRole Binding"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q9: RBAC / ClusterRole Binding (ClusterRoleBinding observer-binding missing or incorrect)"
fi

# Q10: Networking / Network Policies
NP_NAME=$(kubectl get netpol allow-db-access -n database -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$NP_NAME" == "allow-db-access" ]; then
    echo "[PASS] Q10: Networking / Network Policies"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q10: Networking / Network Policies (NetworkPolicy allow-db-access missing in database namespace)"
fi

echo "=============================="
echo "Final Score: $SCORE / $TOTAL"
if [ "$SCORE" -ge 7 ]; then
    echo "Result: PASSED"
else
    echo "Result: FAILED"
fi
