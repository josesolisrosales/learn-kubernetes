# Module 3: Services and Networking

## 🎯 Learning Objectives
- Understand Kubernetes networking fundamentals (cluster IP, pod IP)
- Master different Service types: ClusterIP, NodePort, LoadBalancer
- Implement Ingress controllers and HTTP routing
- Configure internal DNS and service discovery
- Troubleshoot networking issues effectively

## 📁 Module Structure
```
Module-03-Services-Networking/
├── README.md (this file)
└── resources/
    ├── networking-basics/
    │   ├── pod-to-pod-communication.yaml
    │   ├── cluster-ip-demo.yaml
    │   └── network-policy-examples.yaml
    ├── service-types/
    │   ├── clusterip-service.yaml
    │   ├── nodeport-service.yaml
    │   ├── loadbalancer-service.yaml
    │   └── service-comparison-demo.yaml
    ├── ingress-routing/
    │   ├── basic-ingress.yaml
    │   ├── path-based-routing.yaml
    │   ├── host-based-routing.yaml
    │   └── ssl-termination.yaml
    ├── dns-service-discovery/
    │   ├── dns-lookup-demo.yaml
    │   ├── cross-namespace-communication.yaml
    │   └── external-service-mapping.yaml
    └── exercises/
        ├── microservices-communication/
        │   ├── frontend-backend-demo/
        │   └── multi-tier-networking/
        ├── troubleshooting/
        │   ├── broken-services.yaml
        │   └── network-debugging-guide.md
        └── advanced-scenarios/
            ├── canary-deployment-networking.yaml
            ├── blue-green-services.yaml
            └── service-mesh-basics.yaml
```

## 📖 Theory

### Kubernetes Networking Fundamentals

#### Network Model Overview
Kubernetes implements a flat network model where:
- **Every Pod gets its own IP address**
- **Pods can communicate directly** without NAT
- **Services provide stable endpoints** for pod groups
- **Ingress manages external access** to services

```
┌─────────────────────────────────────────────────┐
│                  Kubernetes Cluster             │
│                                                 │
│  ┌─────────────┐    ┌─────────────┐             │
│  │    Node 1   │    │    Node 2   │             │
│  │             │    │             │             │
│  │ ┌─────────┐ │    │ ┌─────────┐ │             │
│  │ │Pod A    │ │    │ │Pod C    │ │             │
│  │ │10.1.1.2 │ │    │ │10.1.2.4 │ │             │
│  │ └─────────┘ │    │ └─────────┘ │             │
│  │ ┌─────────┐ │    │ ┌─────────┐ │             │
│  │ │Pod B    │ │    │ │Pod D    │ │             │
│  │ │10.1.1.3 │ │    │ │10.1.2.5 │ │             │
│  │ └─────────┘ │    │ └─────────┘ │             │
│  └─────────────┘    └─────────────┘             │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │           Service Layer                   │  │
│  │  ┌─────────────┐  ┌─────────────┐         │  │
│  │  │Service A    │  │Service B    │         │  │
│  │  │10.96.1.100  │  │10.96.1.200  │         │  │
│  │  └─────────────┘  └─────────────┘         │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

#### IP Address Ranges

| Component | IP Range | Purpose |
|-----------|----------|---------|
| **Pod IPs** | 10.244.0.0/16 | Individual pod networking |
| **Service IPs** | 10.96.0.0/12 | Service cluster IPs |
| **Node IPs** | Varies | Physical/VM node addresses |

### Service Types Deep Dive

#### ClusterIP (Default)
- **Purpose**: Internal communication within cluster
- **IP Range**: Service subnet (e.g., 10.96.0.0/12)
- **Access**: Only from within cluster
- **Use Cases**: Database services, internal APIs, microservice communication

```yaml
apiVersion: v1
kind: Service
metadata:
  name: internal-api
spec:
  type: ClusterIP  # Default, can be omitted
  selector:
    app: api-server
  ports:
  - port: 80
    targetPort: 8080
```

#### NodePort
- **Purpose**: Expose service on each node's IP at a static port
- **Port Range**: 30000-32767 (configurable)
- **Access**: `<NodeIP>:<NodePort>` from external clients
- **Use Cases**: Development, testing, simple external access

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-web
spec:
  type: NodePort
  selector:
    app: web-server
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080  # Optional, auto-assigned if not specified
```

#### LoadBalancer
- **Purpose**: Expose service via cloud provider's load balancer
- **Requirements**: Cloud provider integration (AWS ELB, GCP LB, Azure LB)
- **Access**: External load balancer IP
- **Use Cases**: Production external services, web applications

```yaml
apiVersion: v1
kind: Service
metadata:
  name: production-web
spec:
  type: LoadBalancer
  selector:
    app: web-server
  ports:
  - port: 80
    targetPort: 8080
```

#### ExternalName
- **Purpose**: Map service to external DNS name
- **No Selectors**: Points to external services
- **Use Cases**: External database, third-party APIs, migration scenarios

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: database.example.com
```

### Service Discovery and DNS

#### Internal DNS Resolution
Kubernetes provides automatic DNS resolution for services:

| DNS Name | Resolves To | Scope |
|----------|-------------|-------|
| `service-name` | Service IP | Same namespace |
| `service-name.namespace` | Service IP | Cross-namespace |
| `service-name.namespace.svc.cluster.local` | Service IP | Fully qualified |

#### DNS Lookup Examples
```bash
# From within a pod:
nslookup my-service                    # Same namespace
nslookup my-service.production         # Different namespace  
nslookup my-service.production.svc.cluster.local  # FQDN

# Environment variables (legacy)
echo $MY_SERVICE_SERVICE_HOST
echo $MY_SERVICE_SERVICE_PORT
```

### Ingress Controllers and Routing

#### What is Ingress?
Ingress manages external access to services via HTTP/HTTPS:
- **Layer 7 Load Balancing**: HTTP(S) routing rules
- **SSL Termination**: Handle TLS certificates
- **Virtual Hosting**: Multiple domains/subdomains
- **Path-based Routing**: Route based on URL paths

#### Ingress Architecture
```
Internet → [Ingress Controller] → [Ingress Rules] → [Services] → [Pods]
```

#### Common Ingress Controllers
- **NGINX Ingress**: Most popular, feature-rich
- **Traefik**: Docker-native, automatic service discovery
- **HAProxy**: High performance, enterprise features
- **Cloud Provider**: AWS ALB, GCP LB, Azure AppGW

#### Ingress Routing Patterns

**Host-based Routing**:
```yaml
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - backend:
          service:
            name: api-service
            port:
              number: 80
  - host: app.example.com
    http:
      paths:
      - backend:
          service:
            name: frontend-service
            port:
              number: 80
```

**Path-based Routing**:
```yaml
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 80
```

## 🛠️ Hands-on Exercises

### Prerequisites
- Completed Modules 1 and 2
- Running Kubernetes cluster with Ingress controller
- kubectl configured and working

### Exercise 3.1: Networking Fundamentals
**Goal**: Understand pod-to-pod communication and service networking

**Files**: `resources/networking-basics/`

**Steps**:
```bash
# Navigate to module directory
cd Module-03-Services-Networking/

# Deploy pods for networking tests
kubectl apply -f resources/networking-basics/pod-to-pod-communication.yaml

# Test direct pod-to-pod communication
kubectl get pods -o wide  # Note the IP addresses

# Access one pod and test connectivity to another
kubectl exec -it client-pod -- ping <server-pod-ip>
kubectl exec -it client-pod -- curl http://<server-pod-ip>:8080

# Observe that pods can communicate directly
```

**Questions to Explore**:
1. Can pods on different nodes communicate directly?
2. What happens if you restart the server pod? Does the IP change?
3. How would you make communication reliable despite IP changes?

### Exercise 3.2: Service Types Comparison
**Goal**: Understand different service types and their use cases

**Files**: `resources/service-types/service-comparison-demo.yaml`

**Steps**:
```bash
# Deploy application with multiple service types
kubectl apply -f resources/service-types/service-comparison-demo.yaml

# Examine different service types
kubectl get services -o wide

# Test ClusterIP service (internal only)
kubectl run test-pod --rm -it --image=busybox -- sh
# Inside pod: wget -qO- clusterip-service
exit

# Test NodePort service (external access)
kubectl get nodes -o wide  # Get node IP
curl http://<node-ip>:30080

# If using cloud provider, test LoadBalancer
kubectl get service loadbalancer-service
# Wait for EXTERNAL-IP to be assigned
curl http://<external-ip>
```

**Compare and Document**:
- Access methods for each service type
- When to use each type
- Advantages and limitations

### Exercise 3.3: DNS and Service Discovery
**Goal**: Master internal DNS resolution and service discovery

**Files**: `resources/dns-service-discovery/dns-lookup-demo.yaml`

**Steps**:
```bash
# Deploy multi-namespace demo
kubectl apply -f resources/dns-service-discovery/dns-lookup-demo.yaml

# Create test namespaces
kubectl create namespace frontend
kubectl create namespace backend

# Deploy services in different namespaces
kubectl apply -f resources/dns-service-discovery/cross-namespace-communication.yaml

# Test DNS resolution patterns
kubectl exec -it dns-test-pod -- nslookup backend-service
kubectl exec -it dns-test-pod -- nslookup backend-service.backend
kubectl exec -it dns-test-pod -- nslookup backend-service.backend.svc.cluster.local

# Test cross-namespace communication
kubectl exec -it frontend-pod -- curl http://backend-service.backend:8080
```

**DNS Resolution Tests**:
```bash
# From frontend namespace pod:
curl http://backend-service.backend:8080        # Cross-namespace
curl http://frontend-service:8080               # Same namespace
curl http://kubernetes.default:443              # System service
```

### Exercise 3.4: Ingress and HTTP Routing
**Goal**: Implement advanced HTTP routing with Ingress

**Files**: `resources/ingress-routing/`

**Step 1 - Install Ingress Controller** (if not present):
```bash
# For NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Wait for controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

**Step 2 - Basic Ingress**:
```bash
# Deploy basic ingress
kubectl apply -f resources/ingress-routing/basic-ingress.yaml

# Check ingress status
kubectl get ingress
kubectl describe ingress basic-ingress

# Test access (may need to setup /etc/hosts for local testing)
curl -H "Host: demo.local" http://<ingress-ip>
```

**Step 3 - Path-based Routing**:
```bash
# Deploy path-based routing
kubectl apply -f resources/ingress-routing/path-based-routing.yaml

# Test different paths
curl -H "Host: app.local" http://<ingress-ip>/api/users
curl -H "Host: app.local" http://<ingress-ip>/admin/dashboard
curl -H "Host: app.local" http://<ingress-ip>/
```

**Step 4 - Host-based Routing**:
```bash
# Deploy host-based routing
kubectl apply -f resources/ingress-routing/host-based-routing.yaml

# Test different hosts
curl -H "Host: api.example.com" http://<ingress-ip>
curl -H "Host: admin.example.com" http://<ingress-ip>
curl -H "Host: app.example.com" http://<ingress-ip>
```

## 🎯 Practice Challenges

### Challenge 3.1: Microservices Communication Architecture
**Location**: `resources/exercises/microservices-communication/`

**Scenario**: Build a complete microservices application with proper service communication

**Architecture Requirements**:
- **Frontend Service**: React/static files (nginx)
- **API Gateway**: Routes requests to backend services
- **User Service**: Handles authentication and user management
- **Product Service**: Manages product catalog
- **Order Service**: Processes orders
- **Database Services**: Persistent storage for each service

**Networking Requirements**:
1. **Frontend** accessible externally via Ingress
2. **API Gateway** accessible from frontend via ClusterIP
3. **Backend services** only accessible from API Gateway
4. **Databases** only accessible from their respective services
5. **Cross-service communication** using service discovery

**Your Deliverables**:
1. All Kubernetes manifests (deployments, services, ingress)
2. Network architecture diagram
3. Service communication documentation
4. Testing procedures for each communication path
5. Performance and security considerations

### Challenge 3.2: Network Troubleshooting
**Location**: `resources/exercises/troubleshooting/`

**Goal**: Become proficient at diagnosing networking issues

**Broken Scenarios**:
1. **Service selector mismatch**: Service can't find pods
2. **Wrong port configuration**: Service pointing to wrong container port
3. **Namespace isolation**: Services in wrong namespaces
4. **Ingress misconfiguration**: Routing rules not working
5. **DNS resolution failures**: Services not discoverable
6. **Network policy blocking**: Pods can't communicate

**Your Tasks**:
- Systematically diagnose each issue
- Document investigation process
- Fix each problem and verify resolution
- Create prevention strategies
- Build troubleshooting runbook

### Challenge 3.3: Advanced Networking Patterns
**Location**: `resources/exercises/advanced-scenarios/`

**Implement These Patterns**:

1. **Canary Deployments with Networking**:
   - Deploy two versions of a service
   - Route 90% traffic to stable, 10% to canary
   - Monitor and gradually shift traffic

2. **Blue-Green Deployments**:
   - Maintain two identical environments
   - Switch traffic instantly between environments
   - Implement rollback capability

3. **Service Mesh Basics**:
   - Implement sidecar proxies for service communication
   - Add observability and traffic management
   - Implement mutual TLS between services

## ❓ Knowledge Check Questions

### Networking Fundamentals
1. **Explain the difference between a Pod IP and a Service IP. Why do we need both?**
2. **How does Kubernetes ensure that pods can communicate across different nodes?**
3. **What happens to network connectivity when a pod restarts? How do services solve this?**

### Service Types
1. **When would you use NodePort vs LoadBalancer vs ClusterIP? Give specific scenarios.**
2. **How does kube-proxy implement service load balancing? What are the different modes?**
3. **What are the security implications of each service type?**

### DNS and Service Discovery
1. **Trace the DNS resolution process when a pod tries to reach 'api-service.production'.**
2. **How would you implement service discovery for external services?**
3. **What are the pros and cons of DNS-based service discovery vs. environment variables?**

### Ingress and Routing
1. **Compare Ingress vs Service LoadBalancer. When would you use each?**
2. **How would you implement SSL termination and certificate management?**
3. **Design a routing strategy for a multi-tenant application.**

### Scenario-Based Questions
1. **Your frontend can't reach the backend API. Walk through your debugging process.**

2. **You need to gradually migrate traffic from an old service to a new one. Design the networking strategy.**

3. **How would you implement a development environment where each developer gets their own isolated services but shares common dependencies?**

## 🚀 Real-world Project

**Project**: E-commerce Platform Networking

**Context**: Build the networking layer for a complete e-commerce platform

**Architecture Requirements**:
- **Web Frontend**: Customer-facing application
- **Mobile API**: REST API for mobile apps
- **Admin Dashboard**: Internal management interface
- **Product Catalog Service**: Product information and search
- **User Management Service**: Authentication and profiles
- **Order Processing Service**: Shopping cart and checkout
- **Payment Service**: Payment processing (mock)
- **Inventory Service**: Stock management
- **Notification Service**: Email/SMS notifications
- **Analytics Service**: Usage tracking and reporting

**Networking Requirements**:
1. **External Access**:
   - Web frontend at www.example.com
   - Mobile API at api.example.com
   - Admin dashboard at admin.example.com

2. **Internal Communication**:
   - Secure service-to-service communication
   - Database access restricted per service
   - Cross-service authentication

3. **Performance Requirements**:
   - Load balancing across service replicas
   - SSL termination at ingress
   - Connection pooling for databases

4. **Security Requirements**:
   - Network policies for service isolation
   - No direct external access to internal services
   - Encrypted communication between services

**Deliverables**:
1. **Complete networking manifests** for all components
2. **Network architecture diagram** showing all communication paths
3. **Security analysis** documenting access controls
4. **Performance testing plan** for network bottlenecks
5. **Monitoring and alerting** for network health
6. **Disaster recovery plan** for network failures
7. **Scaling strategy** for high-traffic scenarios

**Bonus Requirements**:
- Implement service mesh (Istio/Linkerd) for advanced traffic management
- Add distributed tracing for request flow analysis
- Implement rate limiting and circuit breakers
- Create automated network policy testing

## 🔍 Troubleshooting Guide

### Network Issues Diagnostic Tree

```
Service Not Reachable?
├── Check Service Status
│   ├── kubectl get services
│   ├── kubectl describe service <name>
│   └── kubectl get endpoints <name>
├── Service Has No Endpoints?
│   ├── Check selector labels: kubectl get pods --show-labels
│   ├── Verify pod readiness: kubectl get pods
│   └── Check service selector matches pod labels
├── Endpoints Exist But Still Not Reachable?
│   ├── Test from within cluster: kubectl run test-pod --rm -it --image=busybox
│   ├── Check network policies: kubectl get networkpolicies
│   └── Verify target port matches container port
└── External Access Issues?
    ├── NodePort: Check node IPs and port range (30000-32767)
    ├── LoadBalancer: Check cloud provider integration
    └── Ingress: Check ingress controller and rules
```

### Essential Debugging Commands

```bash
# Service investigation
kubectl get services -o wide
kubectl describe service <service-name>
kubectl get endpoints <service-name>

# Pod network details
kubectl get pods -o wide
kubectl describe pod <pod-name>
kubectl exec -it <pod-name> -- ip addr show

# DNS debugging
kubectl exec -it <pod-name> -- nslookup <service-name>
kubectl exec -it <pod-name> -- cat /etc/resolv.conf

# Ingress debugging
kubectl get ingress
kubectl describe ingress <ingress-name>
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Network connectivity testing
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash
# Inside netshoot: dig, ping, curl, tcpdump, etc.
```

### Common Issues and Solutions

| Problem | Symptoms | Investigation | Solution |
|---------|----------|---------------|----------|
| Service not found | DNS resolution fails | Check service exists, namespace | Create service or fix namespace |
| No endpoints | Service has no target pods | Check pod labels vs service selector | Fix selector or pod labels |
| Connection refused | TCP connection fails | Check target port configuration | Fix service targetPort |
| Timeout | Requests hang | Check network policies, firewall | Review network policies |
| Ingress 404 | Page not found | Check ingress rules and paths | Fix ingress path configuration |
| SSL issues | Certificate errors | Check TLS configuration | Fix certificates or ingress TLS |

## 📚 Additional Resources

### Official Documentation
- [Kubernetes Networking Concepts](https://kubernetes.io/docs/concepts/services-networking/)
- [Service Types](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)

### Networking Deep Dives
- [Kubernetes Networking Model](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

### Tools and Utilities
- [kubectl Port Forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)
- [Network Debugging Tools](https://github.com/nicolaka/netshoot)

## ✅ Module Completion Checklist

Before moving to the next module, ensure you can:

- [ ] Explain Kubernetes networking model and IP address allocation
- [ ] Create and use all four service types appropriately
- [ ] Implement DNS-based service discovery across namespaces
- [ ] Configure Ingress with path-based and host-based routing
- [ ] Debug network connectivity issues systematically
- [ ] Design secure service communication architectures
- [ ] Implement load balancing and traffic routing strategies
- [ ] Complete the e-commerce networking project successfully

## ➡️ Next Module

Ready to continue? Proceed to **[Module 4: Storage and Configuration](../Module-04-Storage-Configuration/README.md)** where you'll master:
- Persistent Volumes and Persistent Volume Claims
- ConfigMaps and Secrets management
- Storage Classes and dynamic provisioning
- Stateful applications and data persistence
