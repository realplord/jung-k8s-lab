# CKA Mock Exam 03 (Kubernetes Gateway API)

**Time:** 120 Minutes
**Total Score:** 10 Points
**Passing Score:** 7 Points

Please ensure you run `./setup.sh` before starting this exam. You may use the official Kubernetes or Gateway API documentation during the exam.

---

### Question 1: Provisioning a Shared Gateway (1 point)
Create a Gateway resource named `shared-gateway` in the namespace `infra-ns` using the `envoy-gateway` GatewayClass. 
The Gateway should listen on port `80` (HTTP) with the listener name `http`.
Configure it to allow route attachments from **all namespaces** (`from: All`).

### Question 2: Basic HTTPRoute Path Routing (1 point)
Create an HTTPRoute resource named `alpha-route` in the `alpha` namespace. 
- It should attach to the `shared-gateway` in the `infra-ns` namespace.
- It should match requests for the hostname `alpha.example.com` with the path prefix `/api`.
- All matched traffic should be forwarded to the Service `alpha-svc` on port `8080` in the `alpha` namespace.

### Question 3: Split Traffic / Canary Routing (1 point)
Create an HTTPRoute named `canary-route` in the `production` namespace.
- It should attach to the `shared-gateway` in `infra-ns`.
- It should match traffic for host `app.example.com`.
- Route traffic dynamically split between two services in the `production` namespace:
  - `app-v1` on port `80` with a weight of `90`
  - `app-v2` on port `80` with a weight of `10`

### Question 4: Header-Based Routing (1 point)
Create an HTTPRoute named `version-router` in the `beta` namespace.
- It should attach to the `shared-gateway` in `infra-ns` and match traffic for host `beta.example.com`.
- If a request contains the HTTP header `version: v2`, forward the traffic to the Service `beta-v2-svc` on port `80`.
- For all other default requests, forward traffic to the Service `beta-v1-svc` on port `80`.

### Question 5: HTTP Path Redirects (1 point)
Create an HTTPRoute named `legacy-redirect` in the `default` namespace.
- It should attach to the `shared-gateway` in `infra-ns` and match traffic for the host `example.com`.
- If a request has the path prefix `/legacy`, redirect it with a `301` (Moved Permanently) status code to the path prefix `/new-api`. No traffic should hit a backend service for this rule.

### Question 6: URL Prefix Rewriting (1 point)
Create an HTTPRoute named `rewrite-route` in the `default` namespace.
- It should attach to the `shared-gateway` in `infra-ns` and match traffic for the host `example.com`.
- When requests hit path prefix `/v1/service`, rewrite the URL path prefix to `/service` before forwarding the request to the Service `backend-svc` on port `8080` in the `default` namespace.

### Question 7: Cross-Namespace Ingress Restrictions (1 point)
Create a Gateway resource named `secure-gateway` in the `secure-infra` namespace using the `envoy-gateway` GatewayClass.
- The Gateway should listen on port `80` (HTTP) with name `http`.
- Restrict route attachment: configure the listener to *only* accept HTTPRoutes from namespaces that have the label `environment: production`.

### Question 8: Troubleshooting Route Attachment (1 point)
A pre-deployed HTTPRoute named `broken-route` in the `gamma` namespace is currently failing to attach to `shared-gateway`.
- Diagnose why it is not reconciling properly.
- Fix all errors in the HTTPRoute definition so that it attaches successfully to `shared-gateway` and achieves a `Reconciled` / `Accepted` status.

### Question 9: HTTP Response Header Modification (1 point)
Create an HTTPRoute named `header-enricher` in the `default` namespace.
- It should attach to the `shared-gateway` in `infra-ns` and match traffic for host `web.example.com`.
- Route traffic to the Service `web-svc` on port `80`.
- Apply a filter to inject a custom response header `x-gateway-provider: envoy` on all successfully completed requests.

### Question 10: Multi-Host Routing (1 point)
Create a single HTTPRoute named `multi-host-route` in the `default` namespace.
- It should attach to the `shared-gateway` in `infra-ns`.
- Configure the route to handle traffic for two distinct hostnames:
  - Requests for `shop.example.com` should route to the Service `shop-svc` on port `80`.
  - Requests for `blog.example.com` should route to the Service `blog-svc` on port `80`.
