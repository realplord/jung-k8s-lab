# CKA Exam Curriculum - Domains & Competencies

## 1. Storage (10%)
- **Dynamic Provisioning:** Implement storage classes and dynamic volume provisioning.
- **Volume Configuration:** Configure volume types, access modes, and reclaim policies.
- **PV & PVC Management:** Manage Persistent Volumes (PV) and Persistent Volume Claims (PVC).

## 2. Troubleshooting (30%)
- **Clusters & Nodes:** Troubleshoot clusters and nodes (e.g., node failures, kubelet issues).
- **Cluster Components:** Troubleshoot core control plane components (api-server, scheduler, controller-manager).
- **Resource Monitoring:** Monitor cluster and application resource usage (CPU/memory, metrics-server).
- **Container Streams:** Manage and evaluate container output streams (logging, sidecar setups).
- **Networking & Services:** Troubleshoot services and networking (CoreDNS, kube-proxy, connection issues).

## 3. Workloads & Scheduling (15%)
- **Deployments & Rollouts:** Understand application deployments and how to perform rolling updates and rollbacks.
- **Application Configuration:** Use ConfigMaps and Secrets to configure applications.
- **Autoscaling:** Configure workload autoscaling (Horizontal Pod Autoscalers).
- **Self-Healing:** Understand the primitives used to create robust, self-healing, application deployments.
- **Pod Scheduling:** Configure Pod admission and scheduling (resource limits, node selector, node affinity, taints/tolerations).

## 4. Cluster Architecture, Installation & Configuration (25%)
- **RBAC:** Manage role-based access control (ServiceAccounts, Roles, RoleBindings, ClusterRoles, ClusterRoleBindings).
- **Infrastructure Prep:** Prepare underlying infrastructure for installing a Kubernetes cluster.
- **Cluster Provisioning:** Create and manage Kubernetes clusters using `kubeadm`.
- **Cluster Lifecycle:** Manage the lifecycle of Kubernetes clusters (e.g., cluster upgrades).
- **Highly-Available Control Plane:** Implement and configure a highly-available control plane.
- **Helm & Kustomize:** Use Helm and Kustomize to install cluster components.
- **Extension Interfaces:** Understand extension interfaces (CNI, CSI, CRI, etc.).
- **CRDs & Operators:** Understand Custom Resource Definitions (CRDs), install and configure operators.

## 5. Services & Networking (20%)
- **Pod Connectivity:** Understand connectivity between Pods (pod-to-pod communication).
- **Network Policies:** Define and enforce Network Policies (Ingress/Egress firewall rules).
- **Services & Endpoints:** Use ClusterIP, NodePort, LoadBalancer service types and endpoints.
- **Gateway API:** Use the Gateway API to manage Ingress traffic.
- **Ingress Resources:** Know how to use Ingress controllers and Ingress resources.
- **CoreDNS:** Understand and use CoreDNS for service discovery.
