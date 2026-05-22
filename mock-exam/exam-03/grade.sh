#!/bin/bash
SCORE=0
TOTAL=10

echo "Grading CKA Mock Exam 03 (Gateway API)..."
echo "=========================================="

# Q1: Provisioning a Shared Gateway
GW_NAME=$(kubectl get gateway shared-gateway -n infra-ns -o jsonpath='{.metadata.name}' 2>/dev/null)
GW_CLASS=$(kubectl get gateway shared-gateway -n infra-ns -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null)
GW_PORT=$(kubectl get gateway shared-gateway -n infra-ns -o jsonpath='{.spec.listeners[?(@.name=="http")].port}' 2>/dev/null)
GW_FROM=$(kubectl get gateway shared-gateway -n infra-ns -o jsonpath='{.spec.listeners[?(@.name=="http")].allowedRoutes.namespaces.from}' 2>/dev/null)
GW_ACCEPTED=$(kubectl get gateway shared-gateway -n infra-ns -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}' 2>/dev/null)

if [ "$GW_NAME" == "shared-gateway" ] && [ "$GW_CLASS" == "envoy-gateway" ] && [ "$GW_PORT" == "80" ] && [ "$GW_FROM" == "All" ] && [ "$GW_ACCEPTED" == "True" ]; then
    echo "[PASS] Q1: Provisioning a Shared Gateway"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q1: Provisioning a Shared Gateway (shared-gateway missing, misconfigured, or not Accepted)"
fi

# Q2: Basic HTTPRoute Path Routing
HR_NAME=$(kubectl get httproute alpha-route -n alpha -o jsonpath='{.metadata.name}' 2>/dev/null)
HR_PARENT_GW=$(kubectl get httproute alpha-route -n alpha -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null)
HR_PARENT_NS=$(kubectl get httproute alpha-route -n alpha -o jsonpath='{.spec.parentRefs[0].namespace}' 2>/dev/null)
HR_HOSTS=$(kubectl get httproute alpha-route -n alpha -o jsonpath='{.spec.hostnames[0]}' 2>/dev/null)
HR_MATCH_TYPE=$(kubectl get httproute alpha-route -n alpha -o jsonpath='{.spec.rules[0].matches[0].path.type}' 2>/dev/null)
HR_MATCH_VAL=$(kubectl get httproute alpha-route -n alpha -o jsonpath='{.spec.rules[0].matches[0].path.value}' 2>/dev/null)
HR_BACKEND=$(kubectl get httproute alpha-route -n alpha -o jsonpath='{.spec.rules[0].backendRefs[0].name}' 2>/dev/null)
HR_BACKEND_PORT=$(kubectl get httproute alpha-route -n alpha -o jsonpath='{.spec.rules[0].backendRefs[0].port}' 2>/dev/null)
HR_ACCEPTED=$(kubectl get httproute alpha-route -n alpha -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)

if [ "$HR_NAME" == "alpha-route" ] && [ "$HR_PARENT_GW" == "shared-gateway" ] && [ "$HR_PARENT_NS" == "infra-ns" ] && [ "$HR_HOSTS" == "alpha.example.com" ] && [ "$HR_MATCH_TYPE" == "PathPrefix" ] && [ "$HR_MATCH_VAL" == "/api" ] && [ "$HR_BACKEND" == "alpha-svc" ] && [ "$HR_BACKEND_PORT" -eq 8080 ] 2>/dev/null && [ "$HR_ACCEPTED" == "True" ]; then
    echo "[PASS] Q2: Basic HTTPRoute Path Routing"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q2: Basic HTTPRoute Path Routing (HTTPRoute alpha-route missing, misconfigured, or not Accepted by parent)"
fi

# Q3: Split Traffic / Canary Routing
CR_NAME=$(kubectl get httproute canary-route -n production -o jsonpath='{.metadata.name}' 2>/dev/null)
CR_PARENT_GW=$(kubectl get httproute canary-route -n production -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null)
CR_PARENT_NS=$(kubectl get httproute canary-route -n production -o jsonpath='{.spec.parentRefs[0].namespace}' 2>/dev/null)
CR_HOSTS=$(kubectl get httproute canary-route -n production -o jsonpath='{.spec.hostnames[0]}' 2>/dev/null)
CR_B1_NAME=$(kubectl get httproute canary-route -n production -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="app-v1")].name}' 2>/dev/null)
CR_B1_PORT=$(kubectl get httproute canary-route -n production -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="app-v1")].port}' 2>/dev/null)
CR_B1_WEIGHT=$(kubectl get httproute canary-route -n production -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="app-v1")].weight}' 2>/dev/null)
CR_B2_NAME=$(kubectl get httproute canary-route -n production -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="app-v2")].name}' 2>/dev/null)
CR_B2_PORT=$(kubectl get httproute canary-route -n production -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="app-v2")].port}' 2>/dev/null)
CR_B2_WEIGHT=$(kubectl get httproute canary-route -n production -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="app-v2")].weight}' 2>/dev/null)
CR_ACCEPTED=$(kubectl get httproute canary-route -n production -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)

if [ "$CR_NAME" == "canary-route" ] && [ "$CR_PARENT_GW" == "shared-gateway" ] && [ "$CR_PARENT_NS" == "infra-ns" ] && [ "$CR_HOSTS" == "app.example.com" ] && \
   [ "$CR_B1_NAME" == "app-v1" ] && [ "$CR_B1_PORT" -eq 80 ] 2>/dev/null && [ "$CR_B1_WEIGHT" -eq 90 ] 2>/dev/null && \
   [ "$CR_B2_NAME" == "app-v2" ] && [ "$CR_B2_PORT" -eq 80 ] 2>/dev/null && [ "$CR_B2_WEIGHT" -eq 10 ] 2>/dev/null && [ "$CR_ACCEPTED" == "True" ]; then
    echo "[PASS] Q3: Split Traffic / Canary Routing"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q3: Split Traffic / Canary Routing (canary-route missing, not targeting shared-gateway, or weight split is incorrect)"
fi

# Q4: Header-Based Routing
VR_NAME=$(kubectl get httproute version-router -n beta -o jsonpath='{.metadata.name}' 2>/dev/null)
VR_PARENT_GW=$(kubectl get httproute version-router -n beta -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null)
VR_PARENT_NS=$(kubectl get httproute version-router -n beta -o jsonpath='{.spec.parentRefs[0].namespace}' 2>/dev/null)
VR_HOSTS=$(kubectl get httproute version-router -n beta -o jsonpath='{.spec.hostnames[0]}' 2>/dev/null)

# Extract first rule's header matches and backends
VR_MATCH_HDR_NAME=$(kubectl get httproute version-router -n beta -o jsonpath='{.spec.rules[0].matches[0].headers[0].name}' 2>/dev/null)
VR_MATCH_HDR_VAL=$(kubectl get httproute version-router -n beta -o jsonpath='{.spec.rules[0].matches[0].headers[0].value}' 2>/dev/null)
VR_B_V2=$(kubectl get httproute version-router -n beta -o jsonpath='{.spec.rules[0].backendRefs[0].name}' 2>/dev/null)
VR_B_V2_PORT=$(kubectl get httproute version-router -n beta -o jsonpath='{.spec.rules[0].backendRefs[0].port}' 2>/dev/null)

# Default rule (second rule) backends
VR_B_V1=$(kubectl get httproute version-router -n beta -o jsonpath='{.spec.rules[1].backendRefs[0].name}' 2>/dev/null)
VR_B_V1_PORT=$(kubectl get httproute version-router -n beta -o jsonpath='{.spec.rules[1].backendRefs[0].port}' 2>/dev/null)
VR_ACCEPTED=$(kubectl get httproute version-router -n beta -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)

VR_HDR_LOWER=$(echo "$VR_MATCH_HDR_NAME" | tr '[:upper:]' '[:lower:]')

if [ "$VR_NAME" == "version-router" ] && [ "$VR_PARENT_GW" == "shared-gateway" ] && [ "$VR_PARENT_NS" == "infra-ns" ] && [ "$VR_HOSTS" == "beta.example.com" ] && \
   [ "$VR_HDR_LOWER" == "version" ] && [ "$VR_MATCH_HDR_VAL" == "v2" ] && \
   [ "$VR_B_V2" == "beta-v2-svc" ] && [ "$VR_B_V2_PORT" -eq 80 ] 2>/dev/null && \
   [ "$VR_B_V1" == "beta-v1-svc" ] && [ "$VR_B_V1_PORT" -eq 80 ] 2>/dev/null && [ "$VR_ACCEPTED" == "True" ]; then
    echo "[PASS] Q4: Header-Based Routing"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q4: Header-Based Routing (version-router missing, header matching or backends configured incorrectly)"
fi

# Q5: HTTP Path Redirects
LR_NAME=$(kubectl get httproute legacy-redirect -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
LR_PARENT_GW=$(kubectl get httproute legacy-redirect -n default -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null)
LR_PARENT_NS=$(kubectl get httproute legacy-redirect -n default -o jsonpath='{.spec.parentRefs[0].namespace}' 2>/dev/null)
LR_HOSTS=$(kubectl get httproute legacy-redirect -n default -o jsonpath='{.spec.hostnames[0]}' 2>/dev/null)
LR_MATCH_PATH=$(kubectl get httproute legacy-redirect -n default -o jsonpath='{.spec.rules[0].matches[0].path.value}' 2>/dev/null)
LR_FILTER_TYPE=$(kubectl get httproute legacy-redirect -n default -o jsonpath='{.spec.rules[0].filters[0].type}' 2>/dev/null)
LR_REDIRECT_PATH=$(kubectl get httproute legacy-redirect -n default -o jsonpath='{.spec.rules[0].filters[0].requestRedirect.path.replacePrefixMatch}' 2>/dev/null)
LR_STATUS_CODE=$(kubectl get httproute legacy-redirect -n default -o jsonpath='{.spec.rules[0].filters[0].requestRedirect.statusCode}' 2>/dev/null)
LR_ACCEPTED=$(kubectl get httproute legacy-redirect -n default -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)

if [ "$LR_NAME" == "legacy-redirect" ] && [ "$LR_PARENT_GW" == "shared-gateway" ] && [ "$LR_PARENT_NS" == "infra-ns" ] && [ "$LR_HOSTS" == "example.com" ] && \
   [ "$LR_MATCH_PATH" == "/legacy" ] && [ "$LR_FILTER_TYPE" == "RequestRedirect" ] && [ "$LR_REDIRECT_PATH" == "/new-api" ] && \
   [ "$LR_STATUS_CODE" -eq 301 ] 2>/dev/null && [ "$LR_ACCEPTED" == "True" ]; then
    echo "[PASS] Q5: HTTP Path Redirects"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q5: HTTP Path Redirects (legacy-redirect missing, matches, or redirect filter configured incorrectly)"
fi

# Q6: URL Prefix Rewriting
RR_NAME=$(kubectl get httproute rewrite-route -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
RR_PARENT_GW=$(kubectl get httproute rewrite-route -n default -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null)
RR_PARENT_NS=$(kubectl get httproute rewrite-route -n default -o jsonpath='{.spec.parentRefs[0].namespace}' 2>/dev/null)
RR_HOSTS=$(kubectl get httproute rewrite-route -n default -o jsonpath='{.spec.hostnames[0]}' 2>/dev/null)
RR_MATCH_PATH=$(kubectl get httproute rewrite-route -n default -o jsonpath='{.spec.rules[0].matches[0].path.value}' 2>/dev/null)
RR_FILTER_TYPE=$(kubectl get httproute rewrite-route -n default -o jsonpath='{.spec.rules[0].filters[0].type}' 2>/dev/null)
RR_REWRITE_PATH=$(kubectl get httproute rewrite-route -n default -o jsonpath='{.spec.rules[0].filters[0].urlRewrite.path.replacePrefixMatch}' 2>/dev/null)
RR_BACKEND=$(kubectl get httproute rewrite-route -n default -o jsonpath='{.spec.rules[0].backendRefs[0].name}' 2>/dev/null)
RR_BACKEND_PORT=$(kubectl get httproute rewrite-route -n default -o jsonpath='{.spec.rules[0].backendRefs[0].port}' 2>/dev/null)
RR_ACCEPTED=$(kubectl get httproute rewrite-route -n default -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)

if [ "$RR_NAME" == "rewrite-route" ] && [ "$RR_PARENT_GW" == "shared-gateway" ] && [ "$RR_PARENT_NS" == "infra-ns" ] && [ "$RR_HOSTS" == "example.com" ] && \
   [ "$RR_MATCH_PATH" == "/v1/service" ] && [ "$RR_FILTER_TYPE" == "URLRewrite" ] && [ "$RR_REWRITE_PATH" == "/service" ] && \
   [ "$RR_BACKEND" == "backend-svc" ] && [ "$RR_BACKEND_PORT" -eq 8080 ] 2>/dev/null && [ "$RR_ACCEPTED" == "True" ]; then
    echo "[PASS] Q6: URL Prefix Rewriting"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q6: URL Prefix Rewriting (rewrite-route missing, matches, rewrite filter, or backend configured incorrectly)"
fi

# Q7: Cross-Namespace Ingress Restrictions
SG_NAME=$(kubectl get gateway secure-gateway -n secure-infra -o jsonpath='{.metadata.name}' 2>/dev/null)
SG_CLASS=$(kubectl get gateway secure-gateway -n secure-infra -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null)
SG_PORT=$(kubectl get gateway secure-gateway -n secure-infra -o jsonpath='{.spec.listeners[0].port}' 2>/dev/null)
SG_FROM=$(kubectl get gateway secure-gateway -n secure-infra -o jsonpath='{.spec.listeners[0].allowedRoutes.namespaces.from}' 2>/dev/null)
SG_LABEL=$(kubectl get gateway secure-gateway -n secure-infra -o jsonpath='{.spec.listeners[0].allowedRoutes.namespaces.selector.matchLabels.environment}' 2>/dev/null)
SG_ACCEPTED=$(kubectl get gateway secure-gateway -n secure-infra -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}' 2>/dev/null)

if [ "$SG_NAME" == "secure-gateway" ] && [ "$SG_CLASS" == "envoy-gateway" ] && [ "$SG_PORT" -eq 80 ] 2>/dev/null && \
   [ "$SG_FROM" == "Selector" ] && [ "$SG_LABEL" == "production" ] && [ "$SG_ACCEPTED" == "True" ]; then
    echo "[PASS] Q7: Cross-Namespace Ingress Restrictions"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q7: Cross-Namespace Ingress Restrictions (secure-gateway missing, not targeting environment=production namespace label, or not Accepted)"
fi

# Q8: Troubleshooting Route Attachment
BR_NAME=$(kubectl get httproute broken-route -n gamma -o jsonpath='{.metadata.name}' 2>/dev/null)
BR_PARENT_GW=$(kubectl get httproute broken-route -n gamma -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null)
BR_PARENT_NS=$(kubectl get httproute broken-route -n gamma -o jsonpath='{.spec.parentRefs[0].namespace}' 2>/dev/null)
BR_BACKEND=$(kubectl get httproute broken-route -n gamma -o jsonpath='{.spec.rules[0].backendRefs[0].name}' 2>/dev/null)
BR_BACKEND_PORT=$(kubectl get httproute broken-route -n gamma -o jsonpath='{.spec.rules[0].backendRefs[0].port}' 2>/dev/null)
BR_ACCEPTED=$(kubectl get httproute broken-route -n gamma -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)

if [ "$BR_NAME" == "broken-route" ] && [ "$BR_PARENT_GW" == "shared-gateway" ] && [ "$BR_PARENT_NS" == "infra-ns" ] && \
   [ "$BR_BACKEND" == "gamma-svc" ] && [ "$BR_BACKEND_PORT" -eq 80 ] 2>/dev/null && [ "$BR_ACCEPTED" == "True" ]; then
    echo "[PASS] Q8: Troubleshooting Route Attachment"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q8: Troubleshooting Route Attachment (broken-route is not attached to shared-gateway in infra-ns, backend service is still incorrect, or route is not Accepted)"
fi

# Q9: HTTP Response Header Modification
HE_NAME=$(kubectl get httproute header-enricher -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
HE_PARENT_GW=$(kubectl get httproute header-enricher -n default -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null)
HE_PARENT_NS=$(kubectl get httproute header-enricher -n default -o jsonpath='{.spec.parentRefs[0].namespace}' 2>/dev/null)
HE_HOSTS=$(kubectl get httproute header-enricher -n default -o jsonpath='{.spec.hostnames[0]}' 2>/dev/null)
HE_FILTER_TYPE=$(kubectl get httproute header-enricher -n default -o jsonpath='{.spec.rules[0].filters[0].type}' 2>/dev/null)
HE_HEADER_NAME=$(kubectl get httproute header-enricher -n default -o jsonpath='{.spec.rules[0].filters[0].responseHeaderModifier.set[0].name}' 2>/dev/null)
HE_HEADER_VAL=$(kubectl get httproute header-enricher -n default -o jsonpath='{.spec.rules[0].filters[0].responseHeaderModifier.set[0].value}' 2>/dev/null)
HE_BACKEND=$(kubectl get httproute header-enricher -n default -o jsonpath='{.spec.rules[0].backendRefs[0].name}' 2>/dev/null)
HE_BACKEND_PORT=$(kubectl get httproute header-enricher -n default -o jsonpath='{.spec.rules[0].backendRefs[0].port}' 2>/dev/null)
HE_ACCEPTED=$(kubectl get httproute header-enricher -n default -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)

HE_HDR_LOWER=$(echo "$HE_HEADER_NAME" | tr '[:upper:]' '[:lower:]')

if [ "$HE_NAME" == "header-enricher" ] && [ "$HE_PARENT_GW" == "shared-gateway" ] && [ "$HE_PARENT_NS" == "infra-ns" ] && [ "$HE_HOSTS" == "web.example.com" ] && \
   [ "$HE_FILTER_TYPE" == "ResponseHeaderModifier" ] && [ "$HE_HDR_LOWER" == "x-gateway-provider" ] && [ "$HE_HEADER_VAL" == "envoy" ] && \
   [ "$HE_BACKEND" == "web-svc" ] && [ "$HE_BACKEND_PORT" -eq 80 ] 2>/dev/null && [ "$HE_ACCEPTED" == "True" ]; then
    echo "[PASS] Q9: HTTP Response Header Modification"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q9: HTTP Response Header Modification (header-enricher missing, response header filters, or backend configured incorrectly)"
fi

# Q10: Multi-Host Routing
MHR_NAME=$(kubectl get httproute multi-host-route -n default -o jsonpath='{.metadata.name}' 2>/dev/null)
MHR_PARENT_GW=$(kubectl get httproute multi-host-route -n default -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null)
MHR_PARENT_NS=$(kubectl get httproute multi-host-route -n default -o jsonpath='{.spec.parentRefs[0].namespace}' 2>/dev/null)
MHR_HOSTS=$(kubectl get httproute multi-host-route -n default -o jsonpath='{.spec.hostnames[*]}' 2>/dev/null)
MHR_SHOP_SVC=$(kubectl get httproute multi-host-route -n default -o jsonpath='{.spec.rules[*].backendRefs[?(@.name=="shop-svc")].name}' 2>/dev/null)
MHR_SHOP_PORT=$(kubectl get httproute multi-host-route -n default -o jsonpath='{.spec.rules[*].backendRefs[?(@.name=="shop-svc")].port}' 2>/dev/null)
MHR_BLOG_SVC=$(kubectl get httproute multi-host-route -n default -o jsonpath='{.spec.rules[*].backendRefs[?(@.name=="blog-svc")].name}' 2>/dev/null)
MHR_BLOG_PORT=$(kubectl get httproute multi-host-route -n default -o jsonpath='{.spec.rules[*].backendRefs[?(@.name=="blog-svc")].port}' 2>/dev/null)
MHR_RULES_JSON=$(kubectl get httproute multi-host-route -n default -o json 2>/dev/null)
MHR_ACCEPTED=$(kubectl get httproute multi-host-route -n default -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)

if [ "$MHR_NAME" == "multi-host-route" ] && [ "$MHR_PARENT_GW" == "shared-gateway" ] && [ "$MHR_PARENT_NS" == "infra-ns" ] && \
   [[ "$MHR_HOSTS" == *"shop.example.com"* ]] && [[ "$MHR_HOSTS" == *"blog.example.com"* ]] && \
   [ "$MHR_SHOP_SVC" == "shop-svc" ] && [ "$MHR_SHOP_PORT" -eq 80 ] 2>/dev/null && \
   [ "$MHR_BLOG_SVC" == "blog-svc" ] && [ "$MHR_BLOG_PORT" -eq 80 ] 2>/dev/null && \
   echo "$MHR_RULES_JSON" | grep -qi "shop.example.com" && echo "$MHR_RULES_JSON" | grep -qi "blog.example.com" && [ "$MHR_ACCEPTED" == "True" ]; then
    echo "[PASS] Q10: Multi-Host Routing"
    SCORE=$((SCORE + 1))
else
    echo "[FAIL] Q10: Multi-Host Routing (multi-host-route missing, host list, header matching, or backends configured incorrectly)"
fi

echo "=========================================="
echo "Final Score: $SCORE / $TOTAL"
if [ "$SCORE" -ge 7 ]; then
    echo "Result: PASSED"
else
    echo "Result: FAILED"
fi
