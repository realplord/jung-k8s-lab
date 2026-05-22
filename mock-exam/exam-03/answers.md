# CKA Mock Exam 03 Answers & Solutions (Kubernetes Gateway API)

This guide provides the complete, step-by-step solutions and manifests for all 10 questions of CKA Mock Exam 03, focusing entirely on the modern Kubernetes **Gateway API** standards.

---

### Question 1: Provisioning a Shared Gateway (1 point)
**Task:** Create a Gateway named `shared-gateway` in the `infra-ns` namespace using the `envoy-gateway` GatewayClass, listening on port `80` (HTTP) with name `http`, and allowing route attachments from all namespaces.

#### Declarative Solution:
Apply the following Gateway manifest:

```yaml
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
```

#### Verification:
```bash
kubectl get gateway shared-gateway -n infra-ns
kubectl describe gateway shared-gateway -n infra-ns
```

---

### Question 2: Basic HTTPRoute Path Routing (1 point)
**Task:** Create an HTTPRoute named `alpha-route` in the `alpha` namespace that attaches to the `shared-gateway` in `infra-ns`, routes requests for `alpha.example.com` with prefix `/api` to the Service `alpha-svc` on port `8080` in the `alpha` namespace.

#### Declarative Solution:
Apply the following HTTPRoute manifest:

```yaml
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
```

#### Verification:
```bash
kubectl get httproute alpha-route -n alpha
kubectl describe httproute alpha-route -n alpha
```

---

### Question 3: Split Traffic / Canary Routing (1 point)
**Task:** Create an HTTPRoute named `canary-route` in the `production` namespace that attaches to `shared-gateway` in `infra-ns`, matching host `app.example.com`, and splitting traffic 90/10 between `app-v1` and `app-v2` services on port `80`.

#### Declarative Solution:
Apply the following HTTPRoute manifest:

```yaml
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
```

#### Verification:
```bash
kubectl get httproute canary-route -n production
kubectl describe httproute canary-route -n production
```

---

### Question 4: Header-Based Routing (1 point)
**Task:** Create an HTTPRoute named `version-router` in the `beta` namespace that attaches to `shared-gateway` in `infra-ns`, matching host `beta.example.com`. If the HTTP header `version: v2` is present, route to `beta-v2-svc` on port `80`. Default traffic should go to `beta-v1-svc` on port `80`.

#### Declarative Solution:
Apply the following HTTPRoute manifest:

```yaml
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
```

#### Verification:
```bash
kubectl get httproute version-router -n beta
kubectl describe httproute version-router -n beta
```

---

### Question 5: HTTP Path Redirects (1 point)
**Task:** Create an HTTPRoute named `legacy-redirect` in the `default` namespace that attaches to `shared-gateway` in `infra-ns` matching host `example.com`. Redirect path prefix `/legacy` with a `301` status code to path `/new-api`.

#### Declarative Solution:
Apply the following HTTPRoute manifest:

```yaml
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
```

#### Verification:
```bash
kubectl get httproute legacy-redirect -n default
kubectl describe httproute legacy-redirect -n default
```

---

### Question 6: URL Prefix Rewriting (1 point)
**Task:** Create an HTTPRoute named `rewrite-route` in the `default` namespace that attaches to `shared-gateway` in `infra-ns` matching host `example.com`. Rewrite the path prefix `/v1/service` to `/service` before routing to Service `backend-svc` on port `8080`.

#### Declarative Solution:
Apply the following HTTPRoute manifest:

```yaml
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
```

#### Verification:
```bash
kubectl get httproute rewrite-route -n default
kubectl describe httproute rewrite-route -n default
```

---

### Question 7: Cross-Namespace Ingress Restrictions (1 point)
**Task:** Create a Gateway named `secure-gateway` in `secure-infra` namespace using the `envoy-gateway` GatewayClass, listening on port `80` (HTTP) with name `http`, and restricting route attachments strictly to namespaces labeled with `environment: production`.

#### Declarative Solution:
Apply the following Gateway manifest:

```yaml
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
```

#### Verification:
```bash
kubectl get gateway secure-gateway -n secure-infra
kubectl describe gateway secure-gateway -n secure-infra
```

---

### Question 8: Troubleshooting Route Attachment (1 point)
**Task:** A pre-deployed HTTPRoute named `broken-route` in the `gamma` namespace is failing to attach to `shared-gateway`. Diagnose why it is not reconciling properly, fix all errors in the HTTPRoute definition, and apply the corrected file.

#### Diagnostics & Explanation:
1. **Missing Namespace on parentRef:** The route is in `gamma` but `shared-gateway` is in `infra-ns`. By default, parentRef assumes the route's own namespace. We must explicitly set `namespace: infra-ns` on the parentRef.
2. **Incorrect Backend Service:** The route targets a service named `gamma-service` on port `80`, but the actual pre-deployed service is named `gamma-svc`.

#### Declarative Solution (Fixed YAML):
Apply the following corrected HTTPRoute manifest:

```yaml
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
```

#### Verification:
```bash
kubectl get httproute broken-route -n gamma -o wide
# Check that status.parents[*].conditions matches Accepted: True
kubectl get httproute broken-route -n gamma -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")]}'
```

---

### Question 9: HTTP Response Header Modification (1 point)
**Task:** Create an HTTPRoute named `header-enricher` in the `default` namespace that attaches to `shared-gateway` in `infra-ns`, matching host `web.example.com` and routing to Service `web-svc` on port `80`. Inject custom response header `x-gateway-provider: envoy`.

#### Declarative Solution:
Apply the following HTTPRoute manifest:

```yaml
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
```

#### Verification:
```bash
kubectl get httproute header-enricher -n default
kubectl describe httproute header-enricher -n default
```

---

### Question 10: Multi-Host Routing (1 point)
**Task:** Create a single HTTPRoute named `multi-host-route` in the `default` namespace attaching to `shared-gateway` in `infra-ns`. Requests for `shop.example.com` must route to Service `shop-svc` on port `80`, and requests for `blog.example.com` must route to Service `blog-svc` on port `80`.

#### Declarative Solution:
Apply the following HTTPRoute manifest matching host headers:

```yaml
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
```

#### Verification:
```bash
kubectl get httproute multi-host-route -n default
kubectl describe httproute multi-host-route -n default
```
