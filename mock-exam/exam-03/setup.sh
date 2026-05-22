#!/bin/bash
echo "Setting up CKA Mock Exam 03 (Gateway API)..."

# Check if kubectl is available and cluster is running
if ! kubectl get nodes &> /dev/null; then
    echo "Cluster is not available. Please ensure the cluster is running (e.g. via 'make up-ready' in the project root)."
    exit 1
fi

echo "Cleaning up any old resources..."
# Delete Gateways first to let the controller clean up nicely
kubectl delete gateway shared-gateway -n infra-ns --timeout=10s &>/dev/null || true
kubectl delete gateway secure-gateway -n secure-infra --timeout=10s &>/dev/null || true

# Delete namespaces if they exist
for ns in infra-ns alpha production beta secure-infra gamma; do
    kubectl delete namespace "$ns" &>/dev/null || true
done

# Delete default namespace routes and services to avoid conflicts
kubectl delete httproute legacy-redirect -n default &>/dev/null || true
kubectl delete httproute rewrite-route -n default &>/dev/null || true
kubectl delete httproute header-enricher -n default &>/dev/null || true
kubectl delete httproute multi-host-route -n default &>/dev/null || true
kubectl delete svc backend-svc web-svc shop-svc blog-svc -n default &>/dev/null || true
kubectl delete deployment default-backends -n default &>/dev/null || true

echo "--------------------------------------------------"
echo "Creating namespaces..."
for ns in infra-ns alpha production beta secure-infra gamma; do
    kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

echo "Labeling the production namespace..."
kubectl label namespace production environment=production --overwrite

echo "Deploying mock applications and Services..."

# Namespace: alpha -> Service: alpha-svc:8080
echo "Creating resources in 'alpha' namespace..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alpha-deployment
  namespace: alpha
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alpha-app
  template:
    metadata:
      labels:
        app: alpha-app
    spec:
      containers:
      - name: web
        image: nginx:alpine
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: alpha-svc
  namespace: alpha
spec:
  ports:
  - port: 8080
    targetPort: 80
  selector:
    app: alpha-app
EOF

# Namespace: production -> Services: app-v1:80 and app-v2:80
echo "Creating resources in 'production' namespace..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1-deployment
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-v1
  template:
    metadata:
      labels:
        app: app-v1
    spec:
      containers:
      - name: web
        image: nginx:alpine
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app-v1
  namespace: production
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: app-v1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2-deployment
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-v2
  template:
    metadata:
      labels:
        app: app-v2
    spec:
      containers:
      - name: web
        image: nginx:alpine
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app-v2
  namespace: production
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: app-v2
EOF

# Namespace: beta -> Services: beta-v1-svc:80 and beta-v2-svc:80
echo "Creating resources in 'beta' namespace..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: beta-v1-deployment
  namespace: beta
spec:
  replicas: 1
  selector:
    matchLabels:
      app: beta-v1
  template:
    metadata:
      labels:
        app: beta-v1
    spec:
      containers:
      - name: web
        image: nginx:alpine
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: beta-v1-svc
  namespace: beta
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: beta-v1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: beta-v2-deployment
  namespace: beta
spec:
  replicas: 1
  selector:
    matchLabels:
      app: beta-v2
  template:
    metadata:
      labels:
        app: beta-v2
    spec:
      containers:
      - name: web
        image: nginx:alpine
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: beta-v2-svc
  namespace: beta
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: beta-v2
EOF

# Namespace: default -> Services: backend-svc:8080, web-svc:80, shop-svc:80, blog-svc:80
echo "Creating resources in 'default' namespace..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-backends
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: default-backend
  template:
    metadata:
      labels:
        app: default-backend
    spec:
      containers:
      - name: web
        image: nginx:alpine
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
  namespace: default
spec:
  ports:
  - port: 8080
    targetPort: 80
  selector:
    app: default-backend
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: default
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: default-backend
---
apiVersion: v1
kind: Service
metadata:
  name: shop-svc
  namespace: default
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: default-backend
---
apiVersion: v1
kind: Service
metadata:
  name: blog-svc
  namespace: default
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: default-backend
EOF

# Namespace: gamma -> Service: gamma-svc:80 and misconfigured broken-route
echo "Creating resources in 'gamma' namespace..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gamma-deployment
  namespace: gamma
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gamma-app
  template:
    metadata:
      labels:
        app: gamma-app
    spec:
      containers:
      - name: web
        image: nginx:alpine
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: gamma-svc
  namespace: gamma
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: gamma-app
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: broken-route
  namespace: gamma
spec:
  parentRefs:
  - name: shared-gateway
    # CRITICAL MISSING PIECE: namespace: infra-ns
  hostnames:
  - "gamma.example.com"
  rules:
  - backendRefs:
    - name: gamma-service  # CRITICAL ERROR: typo in service name (should be 'gamma-svc')
      port: 80
EOF

echo "Setup complete. You may begin CKA Mock Exam 03!"
