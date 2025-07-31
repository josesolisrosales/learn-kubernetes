# E-commerce Platform - Complete Kubernetes Solution

This directory contains a comprehensive, production-ready Kubernetes deployment for a multi-tier e-commerce platform. It demonstrates advanced pod patterns, multi-container architectures, persistent storage, networking, and deployment strategies.

## 🏗️ Architecture Overview

The solution implements a complete 3-tier architecture:

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Frontend   │────│   Backend    │────│   Database   │
│   (nginx)    │    │   (API)      │    │ (PostgreSQL) │
│              │    │              │    │              │
│ - Web UI     │    │ - REST API   │    │ - Data Store │
│ - Static     │    │ - Business   │    │ - Backups    │
│   Content    │    │   Logic      │    │ - Monitoring │
└──────────────┘    └──────────────┘    └──────────────┘
```

## 📁 Directory Structure

```
solution/
├── README.md                     # This documentation
├── deploy.sh                     # Deployment script
├── cleanup.sh                    # Cleanup script
├── namespace.yaml                # Namespace and RBAC setup
├── frontend/                     # Frontend tier
│   ├── deployment.yaml          # Multi-container frontend
│   ├── service.yaml             # Frontend services
│   └── configmap.yaml           # Frontend configuration
├── backend/                      # Backend tier
│   ├── deployment.yaml          # API server deployment
│   ├── service.yaml             # Backend services
│   ├── configmap.yaml           # Backend configuration
│   └── secret.yaml              # Backend secrets
├── database/                     # Database tier
│   ├── statefulset.yaml         # PostgreSQL StatefulSet
│   ├── service.yaml             # Database services
│   ├── configmap.yaml           # Database configuration
│   └── secret.yaml              # Database credentials
└── deployment-strategies/        # Advanced deployment patterns
    └── blue-green-setup.yaml    # Blue-green deployment
```

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (v1.20+)
- kubectl configured
- StorageClass named `fast-ssd` available
- At least 4 CPU cores and 8GB RAM available

### 1. Deploy the Complete Solution

```bash
# Clone and navigate to the solution directory
cd Module-02-Pods-YAML-Deep-Dive/resources/exercises/build-from-scratch/solution/

# Deploy everything with the deployment script
./deploy.sh

# Or deploy manually step by step
kubectl apply -f namespace.yaml
kubectl apply -f database/
kubectl apply -f backend/
kubectl apply -f frontend/
```

### 2. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n ecommerce-platform

# Check services
kubectl get svc -n ecommerce-platform

# Check persistent volumes
kubectl get pvc -n ecommerce-platform

# Watch deployment progress
kubectl get pods -n ecommerce-platform -w
```

### 3. Access the Application

```bash
# Get the frontend LoadBalancer IP
kubectl get svc frontend-service -n ecommerce-platform

# Or use port-forward for testing
kubectl port-forward svc/frontend-service 8080:80 -n ecommerce-platform

# Access the application at http://localhost:8080
```

## 🎯 Key Features Demonstrated

### Multi-Container Patterns

1. **Sidecar Containers**
   - Log collectors
   - Metrics exporters
   - Backup agents
   - Circuit breakers

2. **Init Containers**
   - Database schema initialization
   - Directory structure setup
   - Dependency verification
   - Configuration preparation

3. **Ambassador Containers**
   - Connection pooling
   - Protocol translation
   - Rate limiting
   - Monitoring

### Storage Patterns

- **StatefulSet with Persistent Storage**: Database with persistent volumes
- **ConfigMap Volumes**: Configuration management
- **Secret Volumes**: Secure credential handling
- **EmptyDir Volumes**: Shared temporary storage
- **Volume Claim Templates**: Dynamic storage provisioning

### Networking & Services

- **LoadBalancer Service**: External frontend access
- **ClusterIP Services**: Internal communication
- **NodePort Services**: Direct pod access for testing
- **Headless Services**: StatefulSet service discovery
- **Network Policies**: Traffic segmentation and security

### Security Features

- **Pod Security Contexts**: Non-root users, capability dropping
- **Resource Limits**: CPU and memory constraints
- **Network Policies**: Traffic isolation
- **Secrets Management**: Encrypted credential storage
- **RBAC**: Role-based access control

### Health & Monitoring

- **Readiness Probes**: Traffic routing control
- **Liveness Probes**: Automatic pod restarts
- **Startup Probes**: Slow-starting container handling
- **Resource Monitoring**: CPU and memory usage tracking
- **Prometheus Metrics**: Application-level monitoring

## 📊 Component Details

### Frontend Tier (`frontend/`)

**Deployment Features:**
- 3 replicas for high availability
- Nginx web server with custom configuration
- Log collector sidecar
- Metrics exporter sidecar
- Interactive web dashboard
- Health checks and graceful shutdown

**Services:**
- `frontend-service` (LoadBalancer): External access
- `frontend-nodeport` (NodePort): Direct testing access
- `frontend-internal` (ClusterIP): Internal communication

### Backend Tier (`backend/`)

**Deployment Features:**
- 4 replicas for scalability
- API server with comprehensive endpoints
- Circuit breaker sidecar
- Connection pool manager
- Database connection handling
- Advanced health checks

**Services:**
- `backend-service` (ClusterIP): Internal API access
- `backend-nodeport` (NodePort): Direct API testing

**API Endpoints:**
- `/health` - Health check
- `/api/users` - User management
- `/api/products` - Product catalog
- `/api/orders` - Order processing
- `/api/stats` - System statistics

### Database Tier (`database/`)

**StatefulSet Features:**
- PostgreSQL 15 with optimized configuration
- Persistent storage with volume claim templates
- Backup sidecar with automated backups
- Connection pooler simulation
- Prometheus metrics exporter
- Advanced logging and monitoring

**Services:**
- `database-service` (Headless): StatefulSet access
- `database-readonly` (ClusterIP): Read replica access
- `database-nodeport` (NodePort): Development access

**Database Schema:**
- Users table with authentication
- Products table with inventory
- Orders table with relationships
- Order items with product references
- Optimized indexes for performance

## 🔄 Deployment Strategies

### Blue-Green Deployment (`deployment-strategies/`)

The solution includes a complete blue-green deployment setup:

```bash
# Deploy blue-green configuration
kubectl apply -f deployment-strategies/blue-green-setup.yaml

# Test blue environment (current production)
curl http://<node-ip>:30180

# Test green environment (new version)
curl http://<node-ip>:30181

# Switch traffic to green
kubectl patch service frontend-production -n ecommerce-platform \
  -p '{"spec":{"selector":{"environment":"green"}}}'

# Rollback to blue if needed
kubectl patch service frontend-production -n ecommerce-platform \
  -p '{"spec":{"selector":{"environment":"blue"}}}'
```

## 🧪 Testing & Validation

### Automated Testing

```bash
# Run comprehensive tests
./test.sh

# Test individual components
kubectl exec -it <frontend-pod> -n ecommerce-platform -- curl backend-service:8080/health
kubectl exec -it <backend-pod> -n ecommerce-platform -- pg_isready -h database-service -p 5432

# Load testing
kubectl run load-test --image=alpine/curl --rm -it --restart=Never -- \
  sh -c 'for i in {1..100}; do curl http://frontend-service.ecommerce-platform.svc.cluster.local; done'
```

### Manual Testing

1. **Frontend Testing**
   - Access web interface
   - Test API proxy functionality
   - Verify health endpoints

2. **Backend Testing**
   - Test all API endpoints
   - Verify database connectivity
   - Check circuit breaker functionality

3. **Database Testing**
   - Verify data persistence
   - Test backup functionality  
   - Check connection pooling

### Performance Testing

```bash
# CPU and memory usage
kubectl top pods -n ecommerce-platform

# Network performance
kubectl exec -it <pod> -- iperf3 -s
kubectl exec -it <pod> -- iperf3 -c <target-ip>

# Storage performance
kubectl exec -it database-0 -n ecommerce-platform -- \
  dd if=/dev/zero of=/tmp/test bs=1M count=100
```

## 🔧 Configuration Management

### Environment Variables

Key environment variables used across components:

- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis cache connection
- `JWT_SECRET`: Authentication token secret
- `API_RATE_LIMIT`: Rate limiting configuration
- `LOG_LEVEL`: Logging verbosity

### ConfigMaps

- **Frontend**: Nginx configuration, web content
- **Backend**: API configuration, route definitions
- **Database**: PostgreSQL configuration, maintenance scripts

### Secrets

- **Database Credentials**: Username, password, connection strings
- **API Keys**: External service authentication
- **Certificates**: TLS certificates for secure communication

## 📈 Monitoring & Observability

### Metrics Collection

- **Prometheus Metrics**: Application and system metrics
- **Resource Usage**: CPU, memory, storage utilization
- **Network Metrics**: Request rates, latency, error rates
- **Business Metrics**: User activity, transaction volumes

### Logging

- **Structured Logging**: JSON-formatted log entries
- **Log Aggregation**: Centralized log collection
- **Log Levels**: Configurable verbosity levels
- **Audit Logging**: Security and compliance tracking

### Health Checks

- **Readiness Probes**: Service availability
- **Liveness Probes**: Container health
- **Startup Probes**: Initialization monitoring
- **Custom Health Endpoints**: Application-specific checks

## 🛡️ Security Implementation

### Pod Security

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
```

### Container Security

```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  capabilities:
    drop: ["ALL"]
```

### Network Security

- Network policies for traffic isolation
- Service-to-service encryption
- Ingress TLS termination
- API authentication and authorization

## 🔄 Scaling & High Availability

### Horizontal Scaling

```bash
# Scale frontend tier
kubectl scale deployment frontend-deployment --replicas=5 -n ecommerce-platform

# Scale backend tier
kubectl scale deployment backend-deployment --replicas=8 -n ecommerce-platform

# Autoscaling with HPA
kubectl autoscale deployment backend-deployment \
  --cpu-percent=70 --min=2 --max=10 -n ecommerce-platform
```

### Vertical Scaling

```bash
# Update resource limits
kubectl patch deployment frontend-deployment -n ecommerce-platform \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"limits":{"memory":"256Mi","cpu":"200m"}}}]}}}}'
```

### High Availability

- Multi-replica deployments
- Pod anti-affinity rules
- ReadinessProbe-based traffic routing
- Graceful shutdown handling
- Data replication and backups

## 🧹 Cleanup

### Complete Cleanup

```bash
# Use the cleanup script
./cleanup.sh

# Or manually delete resources
kubectl delete namespace ecommerce-platform

# Clean up persistent volumes if needed
kubectl get pv | grep ecommerce-platform
kubectl delete pv <pv-names>
```

### Partial Cleanup

```bash
# Remove only applications, keep data
kubectl delete deployment,service,configmap -n ecommerce-platform --all

# Remove only blue-green deployment
kubectl delete -f deployment-strategies/blue-green-setup.yaml
```

## 🎓 Learning Outcomes

By studying and deploying this solution, you will learn:

1. **Multi-Container Patterns**: Sidecar, init, and ambassador containers
2. **Storage Management**: Persistent volumes, StatefulSets, data persistence
3. **Service Discovery**: DNS-based service resolution, load balancing
4. **Configuration Management**: ConfigMaps, Secrets, environment variables
5. **Security**: Pod security contexts, RBAC, network policies
6. **Monitoring**: Health checks, metrics collection, logging
7. **Deployment Strategies**: Blue-green deployments, rolling updates
8. **Troubleshooting**: Common issues and debugging techniques

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Best Practices Guide](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Monitoring and Logging](https://kubernetes.io/docs/tasks/debug-application-cluster/)

## 🤝 Contributing

This solution is designed for educational purposes. Feel free to:

- Experiment with different configurations
- Add new features and components
- Optimize resource usage
- Implement additional security measures
- Share improvements and learnings

## 📝 License

This educational content is provided under the MIT License. See the main repository for details.