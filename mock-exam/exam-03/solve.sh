#!/bin/bash
set -e

echo "=== Solving Question 1: Provisioning a Shared Gateway ==="
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shared-gateway
  namespace: infra-ns
spec:
  gatewayClassName: envoy-gateway
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: All
EOF

# Wait for shared-gateway to be accepted before attaching routes to it
echo "Waiting for shared-gateway to be Accepted..."
kubectl wait --for=condition=Accepted gateway/shared-gateway -n infra-ns --timeout=30s

echo "=== Solving Question 2: Basic HTTPRoute Path Routing ==="
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: alpha-route
  namespace: alpha
spec:
  parentRefs:
  - name: shared-gateway
    namespace: infra-ns
  hostnames:
  - "alpha.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
    backendRefs:
    - name: alpha-svc
      port: 8080
EOF

echo "=== Solving Question 3: Split Traffic / Canary Routing ==="
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: canary-route
  namespace: production
spec:
  parentRefs:
  - name: shared-gateway
    namespace: infra-ns
  hostnames:
  - "app.example.com"
  rules:
  - backendRefs:
    - name: app-v1
      port: 80
      weight: 90
    - name: app-v2
      port: 80
      weight: 10
EOF

echo "=== Solving Question 4: Header-Based Routing ==="
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: version-router
  namespace: beta
spec:
  parentRefs:
  - name: shared-gateway
    namespace: infra-ns
  hostnames:
  - "beta.example.com"
  rules:
  - matches:
    - headers:
      - name: version
        value: v2
    backendRefs:
    - name: beta-v2-svc
      port: 80
  - backendRefs:
    - name: beta-v1-svc
      port: 80
EOF

echo "=== Solving Question 5: HTTP Path Redirects ==="
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: legacy-redirect
  namespace: default
spec:
  parentRefs:
  - name: shared-gateway
    namespace: infra-ns
  hostnames:
  - "example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /legacy
    filters:
    - type: RequestRedirect
      requestRedirect:
        path:
          type: ReplacePrefixMatch
          replacePrefixMatch: /new-api
        statusCode: 301
EOF

echo "=== Solving Question 6: URL Prefix Rewriting ==="
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: rewrite-route
  namespace: default
spec:
  parentRefs:
  - name: shared-gateway
    namespace: infra-ns
  hostnames:
  - "example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /v1/service
    filters:
    - type: URLRewrite
      urlRewrite:
        path:
          type: ReplacePrefixMatch
          replacePrefixMatch: /service
    backendRefs:
    - name: backend-svc
      port: 8080
EOF

echo "=== Solving Question 7: Cross-Namespace Ingress Restrictions ==="
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: secure-gateway
  namespace: secure-infra
spec:
  gatewayClassName: envoy-gateway
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            environment: production
EOF

echo "=== Solving Question 8: Troubleshooting Route Attachment ==="
# We update the pre-deployed broken-route to correctly reference 'infra-ns' as parentRef namespace
# and change the backendRef name to 'gamma-svc'
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: broken-route
  namespace: gamma
spec:
  parentRefs:
  - name: shared-gateway
    namespace: infra-ns
  hostnames:
  - "gamma.example.com"
  rules:
  - backendRefs:
    - name: gamma-svc
      port: 80
EOF

echo "=== Solving Question 9: HTTP Response Header Modification ==="
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: header-enricher
  namespace: default
spec:
  parentRefs:
  - name: shared-gateway
    namespace: infra-ns
  hostnames:
  - "web.example.com"
  rules:
  - filters:
    - type: ResponseHeaderModifier
      responseHeaderModifier:
        set:
        - name: x-gateway-provider
          value: envoy
    backendRefs:
    - name: web-svc
      port: 80
EOF

echo "=== Solving Question 10: Multi-Host Routing ==="
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: multi-host-route
  namespace: default
spec:
  parentRefs:
  - name: shared-gateway
    namespace: infra-ns
  hostnames:
  - "shop.example.com"
  - "blog.example.com"
  rules:
  - matches:
    - headers:
      - name: host
        value: shop.example.com
    backendRefs:
    - name: shop-svc
      port: 80
  - matches:
    - headers:
      - name: host
        value: blog.example.com
    backendRefs:
    - name: blog-svc
      port: 80
EOF

echo "Waiting for resources to reconcile completely..."
sleep 5
echo "=== All questions solved! ==="
