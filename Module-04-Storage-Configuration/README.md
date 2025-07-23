# Module 4: Storage and Configuration

## 🎯 Learning Objectives

- Master the differences between Volumes, Persistent Volumes, and Persistent Volume Claims
- Implement advanced ConfigMaps and Secrets management strategies
- Configure Storage Classes for dynamic provisioning
- Deploy and manage stateful applications with databases
- Handle configuration updates and secret rotation

## 📁 Module Structure

```
Module-04-Storage-Configuration/
├── README.md (this file)
└── resources/
    ├── volume-fundamentals/
    │   ├── emptydir-vs-hostpath.yaml
    │   ├── volume-types-comparison.yaml
    │   └── volume-lifecycle-demo.yaml
    ├── persistent-storage/
    │   ├── pv-pvc-basic.yaml
    │   ├── dynamic-provisioning.yaml
    │   ├── storage-classes.yaml
    │   └── pvc-expansion-demo.yaml
    ├── configuration-management/
    │   ├── configmap-patterns.yaml
    │   ├── secret-management.yaml
    │   ├── config-hot-reload.yaml
    │   └── environment-specific-configs.yaml
    ├── stateful-applications/
    │   ├── mysql-stateful.yaml
    │   ├── mongodb-replica-set.yaml
    │   ├── postgresql-with-backup.yaml
    │   └── redis-cluster.yaml
    └── exercises/
        ├── wordpress-complete/
        │   ├── mysql-backend/
        │   ├── wordpress-frontend/
        │   └── shared-storage/
        ├── multi-environment/
        │   ├── dev-config/
        │   ├── staging-config/
        │   └── prod-config/
        └── data-migration/
            ├── backup-restore/
            └── storage-upgrade/
```

## 📖 Theory

### Storage in Kubernetes: The Big Picture

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Storage                   │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │   Volumes   │  │    PVs      │  │    PVCs     │      │
│  │  (Pod-tied) │  │ (Cluster    │  │ (Namespace  │      │
│  │             │  │  resource)  │  │  resource)  │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │
│         │                 │                 │           │
│         │                 └─────────────────┘           │
│         │                          │                    │
│  ┌─────────────────────────────────────────────────────┐│
│  │              Storage Classes                        ││
│  │        (Dynamic Provisioning Rules)                 ││
│  └─────────────────────────────────────────────────────┘│
│                                                         │
│  ┌─────────────────────────────────────────────────────┐│
│  │                Physical Storage                     ││
│  │   Cloud Disks | Local Storage | Network Storage     ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

### Volumes vs Persistent Volumes vs PVCs

#### Volumes (Pod-level Storage)

- **Lifecycle**: Tied to pod lifecycle
- **Scope**: Single pod
- **Types**: emptyDir, hostPath, configMap, secret, etc.
- **Use Cases**: Temporary data, shared data between containers, configuration injection

```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    volumeMounts:
    - name: temp-storage
      mountPath: /tmp/data
  volumes:
  - name: temp-storage
    emptyDir: {}  # Dies with pod
```

#### Persistent Volumes (Cluster-level Storage)

- **Lifecycle**: Independent of pods
- **Scope**: Cluster-wide resource
- **Management**: Created by administrators or dynamic provisioning
- **Use Cases**: Long-term data storage, shared storage across pods

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: fast-ssd
  hostPath:
    path: /data/mysql
```

#### Persistent Volume Claims (Storage Requests)

- **Lifecycle**: Independent of pods, tied to namespace
- **Scope**: Namespace resource
- **Purpose**: Request storage with specific requirements
- **Use Cases**: Application storage requests, dynamic provisioning

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: fast-ssd
```

### Volume Types Comparison

| Volume Type | Persistence | Scope | Use Case |
|-------------|-------------|--------|----------|
| **emptyDir** | Pod lifetime | Single pod | Temporary files, cache |
| **hostPath** | Node lifetime | Single node | Node-specific data, debugging |
| **nfs** | External system | Multi-pod | Shared file storage |
| **configMap** | Object lifetime | Configuration | Config files injection |
| **secret** | Object lifetime | Secrets | Credential injection |
| **persistentVolumeClaim** | Independent | Multi-pod | Database storage, user data |

### Storage Classes and Dynamic Provisioning

Storage Classes define how storage is dynamically provisioned:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  fsType: ext4
  encrypted: "true"
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

#### Common Provisioners

- **AWS**: `kubernetes.io/aws-ebs`, `efs.csi.aws.com`
- **GCP**: `kubernetes.io/gce-pd`, `filestore.csi.storage.gke.io`
- **Azure**: `kubernetes.io/azure-disk`, `file.csi.azure.com`
- **Local**: `kubernetes.io/no-provisioner`, `local-path`

### ConfigMaps vs Secrets

#### ConfigMaps: Non-sensitive Configuration

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  # Key-value pairs
  database_host: "mysql.default.svc.cluster.local"
  database_port: "3306"
  debug_mode: "false"
  
  # Configuration files
  nginx.conf: |
    server {
        listen 80;
        location / {
            proxy_pass http://backend;
        }
    }
```

#### Secrets: Sensitive Data

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # Base64 encoded values
  database_password: cGFzc3dvcmQxMjM=
  api_key: YWJjZGVmZ2hpams=
stringData:
  # Plain text (automatically encoded)
  jwt_secret: "my-super-secret-key"
```

#### Secret Types

| Type | Purpose | Example |
|------|---------|---------|
| **Opaque** | Generic secrets | Passwords, API keys |
| **kubernetes.io/tls** | TLS certificates | SSL certs for ingress |
| **kubernetes.io/dockerconfigjson** | Registry credentials | Private image pulls |
| **kubernetes.io/service-account-token** | Service account tokens | API access |

### Configuration Injection Patterns

#### Environment Variables

```yaml
env:
- name: DB_HOST
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: database_host
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: app-secrets
      key: database_password
```

#### Volume Mounts

```yaml
volumeMounts:
- name: config-volume
  mountPath: /etc/config
- name: secret-volume
  mountPath: /etc/secrets
  readOnly: true

volumes:
- name: config-volume
  configMap:
    name: app-config
- name: secret-volume
  secret:
    secretName: app-secrets
    defaultMode: 0400
```

### Stateful Applications Patterns

#### StatefulSet Characteristics

- **Stable Network Identity**: Predictable pod names (app-0, app-1, app-2)
- **Stable Storage**: Each pod gets its own PVC
- **Ordered Deployment**: Pods created/updated/deleted in sequence
- **Headless Service**: Direct pod-to-pod communication

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-headless
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

## 🛠️ Hands-on Exercises

### Prerequisites

- Completed Modules 1-3
- Kubernetes cluster with storage support
- kubectl configured

### Exercise 4.1: Volume Types Exploration

**Goal**: Understand different volume types and their behaviors

**Files**: `resources/volume-fundamentals/`

**Steps**:

```bash
# Navigate to module directory
cd Module-04-Storage-Configuration/

# Deploy volume comparison demo
kubectl apply -f resources/volume-fundamentals/volume-types-comparison.yaml

# Examine different volume types
kubectl get pods volume-demo -o yaml

# Test emptyDir behavior
kubectl exec -it volume-demo -c writer -- sh
# Inside container: echo "test data" > /shared/emptydir-test.txt
exit

kubectl exec -it volume-demo -c reader -- cat /shared/emptydir-test.txt

# Test hostPath persistence
kubectl exec -it volume-demo -c writer -- echo "persistent data" > /host-data/test.txt

# Delete and recreate pod
kubectl delete pod volume-demo
kubectl apply -f resources/volume-fundamentals/volume-types-comparison.yaml

# Check if hostPath data survived (emptyDir won't)
kubectl exec -it volume-demo -c reader -- ls -la /shared/  # Should be empty
kubectl exec -it volume-demo -c reader -- cat /host-data/test.txt  # Should exist
```

**Questions to Explore**:

1. Which volume types survive pod restarts?
2. When would you use each volume type?
3. What are the security implications of hostPath volumes?

### Exercise 4.2: Persistent Volumes and Claims

**Goal**: Master PV/PVC relationship and lifecycle

**Files**: `resources/persistent-storage/pv-pvc-basic.yaml`

**Steps**:

```bash
# Create PV and PVC
kubectl apply -f resources/persistent-storage/pv-pvc-basic.yaml

# Examine the binding process
kubectl get pv
kubectl get pvc
kubectl describe pv mysql-pv
kubectl describe pvc mysql-pvc

# Deploy pod using PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: mysql-test
spec:
  containers:
  - name: mysql
    image: mysql:8.0
    env:
    - name: MYSQL_ROOT_PASSWORD
      value: password123
    volumeMounts:
    - name: mysql-storage
      mountPath: /var/lib/mysql
  volumes:
  - name: mysql-storage
    persistentVolumeClaim:
      claimName: mysql-pvc
EOF

# Check pod status and logs
kubectl get pods
kubectl logs mysql-test

# Test data persistence
kubectl exec -it mysql-test -- mysql -uroot -ppassword123 -e "CREATE DATABASE testdb;"
kubectl exec -it mysql-test -- mysql -uroot -ppassword123 -e "SHOW DATABASES;"

# Delete pod and recreate
kubectl delete pod mysql-test
kubectl apply -f - <<EOF
# Same pod definition as above
EOF

# Verify data survived
kubectl exec -it mysql-test -- mysql -uroot -ppassword123 -e "SHOW DATABASES;"
```

### Exercise 4.3: Dynamic Provisioning with Storage Classes

**Goal**: Use storage classes for automatic PV creation

**Files**: `resources/persistent-storage/dynamic-provisioning.yaml`

**Steps**:

```bash
# Check available storage classes
kubectl get storageclass

# Create PVC with storage class (creates PV automatically)
kubectl apply -f resources/persistent-storage/dynamic-provisioning.yaml

# Watch PV creation
kubectl get pvc -w  # Watch until BOUND
kubectl get pv     # Should see auto-created PV

# Test volume expansion (if supported)
kubectl patch pvc dynamic-pvc -p '{"spec":{"resources":{"requests":{"storage":"15Gi"}}}}'

# Monitor expansion
kubectl get pvc dynamic-pvc -w
```

### Exercise 4.4: Advanced ConfigMap and Secret Patterns

**Goal**: Implement sophisticated configuration management

**Files**: `resources/configuration-management/`

**Step 1 - ConfigMap Patterns**:

```bash
# Deploy comprehensive configmap example
kubectl apply -f resources/configuration-management/configmap-patterns.yaml

# Examine different mounting strategies
kubectl describe pod config-demo

# Test environment variables
kubectl exec -it config-demo -- env | grep -E "(DB_|APP_)"

# Test file mounting
kubectl exec -it config-demo -- ls -la /etc/config/
kubectl exec -it config-demo -- cat /etc/config/app.properties

# Test configuration hot-reload
kubectl exec -it config-demo -- cat /etc/config/dynamic.conf
kubectl patch configmap app-config -p '{"data":{"dynamic.conf":"updated_value=true\nreload_timestamp='$(date)'"}}'

# Wait and check if file updated (may take up to 60 seconds)
kubectl exec -it config-demo -- cat /etc/config/dynamic.conf
```

**Step 2 - Secret Management**:

```bash
# Create secrets with different methods
kubectl create secret generic manual-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123

kubectl apply -f resources/configuration-management/secret-management.yaml

# Examine secret mounting
kubectl exec -it secret-demo -- ls -la /etc/secrets/
kubectl exec -it secret-demo -- cat /etc/secrets/username

# Verify file permissions (should be restrictive)
kubectl exec -it secret-demo -- ls -la /etc/secrets/
```

### Exercise 4.5: Stateful Application Deployment

**Goal**: Deploy and manage a complete stateful application

**Files**: `resources/stateful-applications/mysql-stateful.yaml`

**Steps**:

```bash
# Deploy MySQL StatefulSet
kubectl apply -f resources/stateful-applications/mysql-stateful.yaml

# Watch ordered pod creation
kubectl get pods -w -l app=mysql

# Check StatefulSet status
kubectl get statefulset mysql
kubectl describe statefulset mysql

# Examine persistent volumes
kubectl get pvc -l app=mysql
kubectl get pv

# Test database functionality
kubectl exec -it mysql-0 -- mysql -uroot -p$(kubectl get secret mysql-secret -o jsonpath='{.data.mysql-root-password}' | base64 -d) -e "CREATE DATABASE testdb;"

# Scale StatefulSet
kubectl scale statefulset mysql --replicas=3

# Watch ordered scaling
kubectl get pods -w -l app=mysql

# Test individual pod storage
kubectl exec -it mysql-1 -- mysql -uroot -p$(kubectl get secret mysql-secret -o jsonpath='{.data.mysql-root-password}' | base64 -d) -e "CREATE DATABASE instance1db;"
kubectl exec -it mysql-2 -- mysql -uroot -p$(kubectl get secret mysql-secret -o jsonpath='{.data.mysql-root-password}' | base64 -d) -e "CREATE DATABASE instance2db;"

# Verify data isolation
kubectl exec -it mysql-0 -- mysql -uroot -p$(kubectl get secret mysql-secret -o jsonpath='{.data.mysql-root-password}' | base64 -d) -e "SHOW DATABASES;"
kubectl exec -it mysql-1 -- mysql -uroot -p$(kubectl get secret mysql-secret -o jsonpath='{.data.mysql-root-password}' | base64 -d) -e "SHOW DATABASES;"
```

## 🎯 Practice Challenges

### Challenge 4.1: Complete WordPress Deployment

**Location**: `resources/exercises/wordpress-complete/`

**Goal**: Deploy a production-ready WordPress with MySQL backend

**Requirements**:

1. **MySQL Database**:
   - StatefulSet with persistent storage
   - Root password stored in secret
   - Database and user configuration via ConfigMap
   - Automated backup strategy

2. **WordPress Frontend**:
   - Deployment with multiple replicas
   - Shared storage for uploads/themes
   - Database connection via service discovery
   - Configuration via ConfigMaps and Secrets

3. **Storage Strategy**:
   - MySQL data persistence across restarts
   - WordPress shared file storage (uploads, themes)
   - Backup and restore procedures
   - Storage monitoring and alerting

4. **Security Requirements**:
   - All passwords in secrets
   - Restricted file permissions
   - Network policies for database access
   - Regular security updates

**Your Deliverables**:

1. All Kubernetes manifests
2. Deployment automation scripts
3. Backup and restore procedures
4. Monitoring and alerting setup
5. Scaling and performance optimization guide
6. Disaster recovery plan

### Challenge 4.2: Multi-Environment Configuration

**Location**: `resources/exercises/multi-environment/`

**Goal**: Implement configuration management for dev/staging/prod environments

**Requirements**:

1. **Environment-Specific Configs**:
   - Development: Debug enabled, local storage, mock services
   - Staging: Production-like, external services, monitoring
   - Production: Optimized, secure, highly available

2. **Configuration Strategy**:
   - Shared base configuration
   - Environment-specific overlays
   - Secret management per environment
   - Configuration validation

3. **Deployment Pipeline**:
   - Automated configuration deployment
   - Configuration drift detection
   - Rollback capabilities
   - Change approval workflows

**Scenarios to Handle**:

- Database connection strings per environment
- Feature flags and A/B testing
- External service endpoints
- Monitoring and logging configurations
- Resource limits and requests

### Challenge 4.3: Data Migration and Storage Upgrade

**Location**: `resources/exercises/data-migration/`

**Goal**: Implement data migration and storage upgrade procedures

**Scenarios**:

1. **Storage Class Migration**: Move from standard to SSD storage
2. **Database Version Upgrade**: MySQL 5.7 to 8.0 with data migration
3. **Backup and Restore**: Implement automated backup/restore procedures
4. **Multi-Region Replication**: Setup cross-region data replication

**Requirements**:

- Zero-downtime migration strategies
- Data integrity verification
- Rollback procedures
- Performance impact minimization

## ❓ Knowledge Check Questions

### Storage Concepts

1. **Explain the lifecycle differences between Volumes, PVs, and PVCs. When would you use each?**
2. **How does dynamic provisioning work? What are the benefits and potential issues?**
3. **Compare StatefulSet vs Deployment for database workloads. What are the trade-offs?**

### Configuration Management

1. **When should you use ConfigMaps vs Secrets vs environment variables?**
2. **How would you implement configuration hot-reloading in your applications?**
3. **Design a secret rotation strategy for a production application.**

### Stateful Applications

1. **What challenges do stateful applications face in Kubernetes? How does StatefulSet address them?**
2. **How would you backup and restore data in a StatefulSet?**
3. **Design a database clustering strategy using Kubernetes primitives.**

### Scenario-Based Questions

1. **Your application needs to share files between multiple pod replicas. Design the storage strategy.**

2. **You need to migrate a legacy application with large persistent data. Plan the migration approach.**

3. **Design a multi-tenant application where each tenant has isolated data but shares the same application code.**

## 🚀 Real-world Project

**Project**: Multi-Tier SaaS Application Infrastructure

**Context**: Build the complete storage and configuration infrastructure for a SaaS platform

**Application Architecture**:

- **Frontend**: React SPA with CDN assets
- **API Gateway**: Kong/Nginx with SSL termination
- **Backend Services**: Node.js microservices
- **Databases**: PostgreSQL (primary), Redis (cache), MongoDB (analytics)
- **File Storage**: User uploads, document processing
- **Background Jobs**: Queue processing, data analytics

**Storage Requirements**:

1. **Database Persistence**:
   - PostgreSQL cluster with replication
   - Redis cluster for caching
   - MongoDB sharded cluster
   - Automated backup/restore

2. **File Storage**:
   - User upload storage (images, documents)
   - Shared assets between replicas
   - CDN integration for static assets
   - Data archival strategies

3. **Configuration Management**:
   - Environment-specific configurations
   - Feature flags and A/B testing
   - Secret rotation automation
   - Configuration validation

**Technical Requirements**:

1. **High Availability**: Multi-AZ deployment, data replication
2. **Scalability**: Auto-scaling based on storage metrics
3. **Security**: Encryption at rest/transit, secret management
4. **Backup/Recovery**: Automated backups, point-in-time recovery
5. **Monitoring**: Storage metrics, configuration drift detection
6. **Compliance**: Data retention policies, audit logging

**Deliverables**:

1. **Complete infrastructure manifests**
2. **Storage architecture documentation**
3. **Backup and disaster recovery procedures**
4. **Configuration management strategy**
5. **Monitoring and alerting setup**
6. **Cost optimization analysis**
7. **Security audit and compliance documentation**

**Advanced Features**:

- Implement storage tiering (hot/warm/cold)
- Add data encryption and key management
- Create automated data archival
- Implement cross-region disaster recovery
- Add storage performance monitoring and optimization

## 🔍 Troubleshooting Guide

### Storage Issues Diagnostic Tree

```
Pod Can't Start - Storage Issues?
├── Check PVC Status
│   ├── kubectl get pvc
│   ├── kubectl describe pvc <name>
│   └── PVC Pending?
│       ├── No suitable PV available
│       ├── Storage class issues
│       └── Insufficient resources
├── Check PV Status
│   ├── kubectl get pv
│   ├── kubectl describe pv <name>
│   └── PV Status Issues?
│       ├── Mount failures
│       ├── Permission problems
│       └── Network storage issues
└── Check Pod Events
    ├── kubectl describe pod <name>
    ├── Volume mount failures
    └── Permission denied errors
```

### Configuration Issues Diagnostic Tree

```
Application Configuration Problems?
├── ConfigMap Issues
│   ├── kubectl get configmap
│   ├── kubectl describe configmap <name>
│   └── Data not updating?
│       ├── Check mounting strategy
│       ├── Verify propagation delay
│       └── Check application reload logic
├── Secret Issues
│   ├── kubectl get secrets
│   ├── kubectl describe secret <name>
│   └── Access denied?
│       ├── Check RBAC permissions
│       ├── Verify secret mounting
│       └── Check file permissions
└── Environment Variables
    ├── kubectl exec <pod> -- env
    ├── Check source references
    └── Verify key names
```

### Essential Debugging Commands

```bash
# Storage debugging
kubectl get pv,pvc
kubectl describe pvc <pvc-name>
kubectl get events --field-selector involvedObject.kind=PersistentVolumeClaim

# Configuration debugging
kubectl get configmap,secret
kubectl describe configmap <name>
kubectl get pod <name> -o yaml | grep -A 20 volumes

# StatefulSet debugging
kubectl get statefulset
kubectl describe statefulset <name>
kubectl get pods -l app=<statefulset-name> --sort-by=.metadata.name

# Storage class debugging
kubectl get storageclass
kubectl describe storageclass <name>
```

### Common Issues and Solutions

| Problem | Symptoms | Investigation | Solution |
|---------|----------|---------------|----------|
| PVC stuck Pending | Pod can't start | Check storage class, PV availability | Create PV or fix storage class |
| Mount failures | Pod CrashLoopBackOff | Check volume permissions, paths | Fix mount paths or permissions |
| Config not updating | App uses old config | Check configmap updates, mount type | Use env vars or restart pod |
| Secret access denied | Permission errors | Check secret permissions, RBAC | Fix secret mode or RBAC |
| StatefulSet pods stuck | Pods not starting in order | Check PVC, storage, previous pod | Fix storage or scale down first |

## 📚 Additional Resources

### Official Documentation

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

### Storage Deep Dives

- [Volume Types](https://kubernetes.io/docs/concepts/storage/volumes/)
- [CSI Drivers](https://kubernetes-csi.github.io/docs/)

### Configuration Management

- [Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Managing Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

## ✅ Module Completion Checklist

Before moving to the next module, ensure you can:

- [ ] Explain differences between Volumes, PVs, and PVCs
- [ ] Configure dynamic storage provisioning with Storage Classes
- [ ] Implement advanced ConfigMap and Secret management
- [ ] Deploy and manage StatefulSet applications
- [ ] Handle data persistence and backup strategies
- [ ] Troubleshoot storage and configuration issues
- [ ] Design multi-environment configuration strategies
- [ ] Complete the SaaS platform storage project successfully

## ➡️ Next Module

Ready to continue? Proceed to **[Module 5: Advanced Workloads](../Module-05-Advanced-Workloads/README.md)** where you'll master:

- DaemonSets, Jobs, and CronJobs
- Init containers and sidecar patterns
- Advanced workload scheduling and management
- Batch processing and job queues
