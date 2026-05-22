#!/bin/bash
SCORE=0
TOTAL=10

echo "Grading CKA Mock Exam 01..."
echo "=============================="

# Q1: /var/tmp/ready-nodes.txt exists and has some content (simplistic check)
if [ -f /var/tmp/ready-nodes.txt ] && [ -s /var/tmp/ready-nodes.txt ]; then
    echo "[PASS] Q1: Cluster Architecture"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q1: Cluster Architecture"
fi

# Q2: nginx-resolver pod and nginx-resolver-svc service
POD_EXISTS=$(kubectl get pod nginx-resolver -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
SVC_EXISTS=$(kubectl get svc nginx-resolver-svc -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$POD_EXISTS" == "nginx-resolver" ] && [ "$SVC_EXISTS" == "nginx-resolver-svc" ]; then
    echo "[PASS] Q2: Workloads"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q2: Workloads"
fi

# Q3: broken-deploy has updated image and is ready
IMG=$(kubectl get deploy broken-deploy -n alpha -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
READY=$(kubectl get deploy broken-deploy -n alpha -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$IMG" == "nginx:1.14.3-alpine" ] && [ "$READY" -ge 1 ] 2>/dev/null; then
    echo "[PASS] Q3: Troubleshooting"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q3: Troubleshooting"
fi

# Q4: RBAC processor ServiceAccount, Role, RoleBinding
SA=$(kubectl get sa processor -n project-tiger -o jsonpath='{.metadata.name}' 2>/dev/null)
ROLE=$(kubectl get role processor-role -n project-tiger -o jsonpath='{.metadata.name}' 2>/dev/null)
RB=$(kubectl get rolebinding processor-binding -n project-tiger -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$SA" == "processor" ] && [ "$ROLE" == "processor-role" ] && [ "$RB" == "processor-binding" ]; then
    echo "[PASS] Q4: RBAC"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q4: RBAC"
fi

# Q5: NetworkPolicy deny-all
NP=$(kubectl get netpol deny-all -n secure-ns -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$NP" == "deny-all" ]; then
    echo "[PASS] Q5: Networking"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q5: Networking"
fi

# Q6: Storage
PV=$(kubectl get pv app-data -o jsonpath='{.metadata.name}' 2>/dev/null)
PVC=$(kubectl get pvc app-data-pvc -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$PV" == "app-data" ] && [ "$PVC" == "app-data-pvc" ]; then
    echo "[PASS] Q6: Storage"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q6: Storage"
fi

# Q7: Scheduling high-priority pod
POD_HP=$(kubectl get pod high-priority -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$POD_HP" == "high-priority" ]; then
    echo "[PASS] Q7: Scheduling"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q7: Scheduling"
fi

# Q8: Configuration config-pod
POD_CFG=$(kubectl get pod config-pod -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
CM=$(kubectl get cm app-config -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$POD_CFG" == "config-pod" ] && [ "$CM" == "app-config" ]; then
    echo "[PASS] Q8: Configuration"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q8: Configuration"
fi

# Q9: Logs log-generator.txt
if [ -f /var/tmp/log-generator.txt ] && [ -s /var/tmp/log-generator.txt ]; then
    echo "[PASS] Q9: Logging"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q9: Logging"
fi

# Q10: Ingress web-ingress
ING=$(kubectl get ingress web-ingress -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$ING" == "web-ingress" ]; then
    echo "[PASS] Q10: Ingress"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q10: Ingress"
fi

echo "=============================="
echo "Final Score: $SCORE / $TOTAL"
if [ "$SCORE" -ge 7 ]; then
    echo "Result: PASSED"
else
    echo "Result: FAILED"
fi
