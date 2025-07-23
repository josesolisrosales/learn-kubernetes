# Module 5: Advanced Workloads

## 🎯 Learning Objectives

- Master different workload types: DaemonSets, StatefulSets, Jobs, and CronJobs
- Understand when to use each workload type for specific scenarios
- Implement advanced container patterns: init containers and sidecars
- Design complex application architectures with multiple workload types
- Handle batch processing, scheduled tasks, and system-level services

## 📁 Module Structure

```
Module-05-Advanced-Workloads/
├── README.md (this file)
└── resources/
    ├── workload-types/
    │   ├── daemonset-examples.yaml
    │   ├── statefulset-patterns.yaml
    │   ├── job-patterns.yaml
    │   └── cronjob-examples.yaml
    ├── container-patterns/
    │   ├── init-container-advanced.yaml
    │   ├── sidecar-patterns.yaml
    │   ├── ambassador-pattern.yaml
    │   └── adapter-pattern.yaml
    ├── scheduling-workloads/
    │   ├── node-affinity-examples.yaml
    │   ├── pod-anti-affinity.yaml
    │   ├── taints-tolerations.yaml
    │   └── priority-classes.yaml
    ├── batch-processing/
    │   ├── parallel-jobs.yaml
    │   ├── job-queues.yaml
    │   ├── workflow-management.yaml
    │   └── data-processing-pipeline.yaml
    └── exercises/
        ├── monitoring-stack/
        │   ├── prometheus-daemonset/
        │   ├── grafana-statefulset/
        │   └── alert-manager-deployment/
        ├── data-pipeline/
        │   ├── etl-jobs/
        │   ├── scheduled-reports/
        │   └── data-validation/
        └── system-services/
            ├── log-collection/
            ├── security-scanning/
            └── backup-automation/
```

## 📖 Theory

### Workload Types Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Workloads                     │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ Deployments │  │ StatefulSets│  │ DaemonSets  │          │
│  │ (Stateless) │  │ (Stateful)  │  │ (Per Node)  │          │
│  │             │  │             │  │             │          │
│  │ • Web Apps  │  │ • Databases │  │ • Log Agents│          │
│  │ • APIs      │  │ • Queues    │  │ • Monitoring│          │
│  │ • Caches    │  │ • Clusters  │  │ • Networking│          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │    Jobs     │  │  CronJobs   │  │   Custom    │          │
│  │ (Run Once)  │  │ (Scheduled) │  │ (Operators) │          │
│  │             │  │             │  │             │          │
│  │ • Batch     │  │ • Backups   │  │ • Complex   │          │
│  │ • Migration │  │ • Reports   │  │ • Apps      │          │
│  │ • Processing│  │ • Cleanup   │  │ • Workflows │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### DaemonSets: One Pod Per Node

#### What are DaemonSets?

- **Purpose**: Ensure exactly one pod runs on each node (or subset of nodes)
- **Use Cases**: System daemons, monitoring agents, log collectors, network plugins
- **Scaling**: Automatically scales with cluster size
- **Updates**: Rolling updates across all nodes

#### Common DaemonSet Examples

| Service | Purpose | Pod per Node |
|---------|---------|--------------|
| **Fluentd/Fluent Bit** | Log collection | ✅ Collect logs from each node |
| **Node Exporter** | Metrics collection | ✅ Export node metrics |
| **Calico/Flannel** | Networking | ✅ Network overlay on each node |
| **Security Agents** | Security scanning | ✅ Monitor each node for threats |
| **Storage Drivers** | CSI drivers | ✅ Storage interface per node |

#### DaemonSet Configuration

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      containers:
      - name: fluentd
        image: fluentd:v1.14
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: dockerlogs
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: dockerlogs
        hostPath:
          path: /var/lib/docker/containers
      # Run on all nodes including master
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
```

### StatefulSets: Ordered, Stable Applications

#### StatefulSet Characteristics

- **Stable Network Identity**: Predictable pod names (mysql-0, mysql-1, mysql-2)
- **Stable Storage**: Each pod gets its own persistent volume
- **Ordered Operations**: Sequential creation, updates, and deletion
- **Headless Service**: Direct pod-to-pod communication

#### When to Use StatefulSets

- **Databases**: MySQL, PostgreSQL, MongoDB clusters
- **Message Queues**: RabbitMQ, Apache Kafka
- **Distributed Systems**: Elasticsearch, Cassandra, etcd
- **Stateful Applications**: Any app requiring stable identity/storage

#### StatefulSet vs Deployment

| Aspect | Deployment | StatefulSet |
|--------|------------|-------------|
| **Pod Names** | Random (app-abc123) | Predictable (app-0, app-1) |
| **Storage** | Shared or ephemeral | Individual PVCs per pod |
| **Scaling** | Parallel | Sequential (ordered) |
| **Updates** | Rolling (parallel) | Rolling (ordered) |
| **Use Cases** | Stateless apps | Stateful apps |

### Jobs: Run-to-Completion Workloads

#### Job Types and Patterns

**Single Job (Run Once)**:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
spec:
  template:
    spec:
      containers:
      - name: migrator
        image: migrate:latest
        command: ["./migrate-data.sh"]
      restartPolicy: Never
  backoffLimit: 3
```

**Parallel Jobs (Multiple Pods)**:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-processing
spec:
  parallelism: 5        # Run 5 pods in parallel
  completions: 50       # Need 50 successful completions
  template:
    spec:
      containers:
      - name: worker
        image: worker:latest
      restartPolicy: Never
```

**Work Queue Pattern**:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: queue-processor
spec:
  parallelism: 3        # 3 workers
  # No completions = run until queue empty
  template:
    spec:
      containers:
      - name: worker
        image: queue-worker:latest
        env:
        - name: QUEUE_URL
          value: "redis://queue:6379"
      restartPolicy: Never
```

### CronJobs: Scheduled Jobs

#### CronJob Patterns

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup-tool:latest
            command: ["backup-database.sh"]
          restartPolicy: OnFailure
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  concurrencyPolicy: Forbid  # Don't run concurrent jobs
```

#### Cron Schedule Examples

| Schedule | Description | Use Case |
|----------|-------------|----------|
| `"0 2 * * *"` | Daily at 2 AM | Database backups |
| `"*/15 * * * *"` | Every 15 minutes | Health checks |
| `"0 0 * * 0"` | Weekly on Sunday | Weekly reports |
| `"0 0 1 * *"` | Monthly on 1st | Monthly cleanup |
| `"@daily"` | Daily at midnight | Log rotation |

### Container Patterns Deep Dive

#### Init Container Patterns

**Dependency Checking**:

```yaml
initContainers:
- name: wait-for-db
  image: busybox
  command: ['sh', '-c', 'until nc -z db 5432; do sleep 1; done']
```

**Data Preparation**:

```yaml
initContainers:
- name: setup-data
  image: setup:latest
  command: ["setup-initial-data.sh"]
  volumeMounts:
  - name: data-volume
    mountPath: /data
```

**Configuration Download**:

```yaml
initContainers:
- name: config-downloader
  image: config-fetcher:latest
  env:
  - name: CONFIG_URL
    value: "https://config-server/app-config"
  volumeMounts:
  - name: config-volume
    mountPath: /config
```

#### Sidecar Patterns

**Log Processing Sidecar**:

- **Main Container**: Application writes logs to shared volume
- **Sidecar Container**: Processes, filters, and forwards logs
- **Communication**: Shared filesystem

**Proxy Sidecar (Ambassador Pattern)**:

- **Main Container**: Application connects to localhost
- **Sidecar Container**: Proxy handles external connections
- **Benefits**: SSL termination, load balancing, retry logic

**Adapter Sidecar**:

- **Main Container**: Legacy application with non-standard output
- **Sidecar Container**: Adapts output to standard format
- **Use Case**: Monitoring integration, log formatting

## 🛠️ Hands-on Exercises

### Prerequisites

- Completed Modules 1-4
- Kubernetes cluster with multiple nodes (for DaemonSet testing)
- kubectl configured

### Exercise 5.1: DaemonSet Deployment and Management

**Goal**: Understand DaemonSet behavior and node-level services

**Files**: `resources/workload-types/daemonset-examples.yaml`

**Steps**:

```bash
# Navigate to module directory
cd Module-05-Advanced-Workloads/

# Deploy log collection DaemonSet
kubectl apply -f resources/workload-types/daemonset-examples.yaml

# Observe DaemonSet behavior
kubectl get daemonset
kubectl get pods -l app=log-collector -o wide

# Check that one pod runs on each node
kubectl get nodes
kubectl get pods -l app=log-collector --field-selector spec.nodeName=<node-name>

# Test DaemonSet updates
kubectl set image daemonset/log-collector fluentd=fluentd:v1.15

# Watch rolling update across nodes
kubectl rollout status daemonset/log-collector
kubectl get pods -l app=log-collector -w

# Add a new node (if possible) and observe automatic scheduling
# Or simulate by uncordoning a node
kubectl get nodes
```

**Advanced DaemonSet Testing**:

```bash
# Test node selector
kubectl label node <node-name> environment=production

# Apply DaemonSet with node selector
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: production-monitor
spec:
  selector:
    matchLabels:
      app: prod-monitor
  template:
    metadata:
      labels:
        app: prod-monitor
    spec:
      nodeSelector:
        environment: production
      containers:
      - name: monitor
        image: monitor:latest
EOF

# Verify it only runs on labeled nodes
kubectl get pods -l app=prod-monitor -o wide
```

### Exercise 5.2: StatefulSet Deep Dive

**Goal**: Master StatefulSet behavior, scaling, and persistence

**Files**: `resources/workload-types/statefulset-patterns.yaml`

**Steps**:

```bash
# Deploy a StatefulSet with persistent storage
kubectl apply -f resources/workload-types/statefulset-patterns.yaml

# Watch ordered pod creation
kubectl get pods -w -l app=web-stateful

# Examine pod names and storage
kubectl get pods -l app=web-stateful
kubectl get pvc -l app=web-stateful

# Test ordered scaling
kubectl scale statefulset web-stateful --replicas=5

# Watch sequential pod creation
kubectl get pods -w -l app=web-stateful

# Test data persistence per pod
kubectl exec -it web-stateful-0 -- echo "data from pod 0" > /data/pod-data.txt
kubectl exec -it web-stateful-1 -- echo "data from pod 1" > /data/pod-data.txt

# Delete pods and verify data persistence
kubectl delete pod web-stateful-0
kubectl wait --for=condition=Ready pod/web-stateful-0

# Check data survived
kubectl exec -it web-stateful-0 -- cat /data/pod-data.txt
```

**StatefulSet Networking Test**:

```bash
# Create headless service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: web-headless
spec:
  clusterIP: None
  selector:
    app: web-stateful
  ports:
  - port: 80
EOF

# Test individual pod DNS resolution
kubectl run test-pod --rm -it --image=busybox -- sh
# Inside pod:
nslookup web-stateful-0.web-headless.default.svc.cluster.local
nslookup web-stateful-1.web-headless.default.svc.cluster.local
ping web-stateful-0.web-headless.default.svc.cluster.local
exit
```

### Exercise 5.3: Jobs and Batch Processing

**Goal**: Implement various job patterns for batch processing

**Files**: `resources/workload-types/job-patterns.yaml`

**Steps**:

```bash
# Single completion job
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: single-job
spec:
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ["sh", "-c", "echo 'Processing data...' && sleep 10 && echo 'Done!'"]
      restartPolicy: Never
  backoffLimit: 3
EOF

# Watch job completion
kubectl get job single-job -w
kubectl logs job/single-job

# Parallel job with multiple completions
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-job
spec:
  parallelism: 3
  completions: 9
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ["sh", "-c", "echo 'Worker starting...' && sleep $((RANDOM % 10 + 5)) && echo 'Work completed'"]
      restartPolicy: Never
EOF

# Monitor parallel execution
kubectl get job parallel-job -w
kubectl get pods -l job-name=parallel-job

# Work queue pattern (no completions specified)
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: queue-job
spec:
  parallelism: 2
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ["sh", "-c", "
          for i in $(seq 1 5); do
            echo 'Processing item $i'
            sleep 2
          done
          echo 'Queue empty, exiting'
        "]
      restartPolicy: Never
EOF
```

### Exercise 5.4: CronJobs and Scheduled Tasks

**Goal**: Implement scheduled jobs with different patterns

**Files**: `resources/workload-types/cronjob-examples.yaml`

**Steps**:

```bash
# Create a simple CronJob (runs every minute for testing)
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-cron
spec:
  schedule: "*/1 * * * *"  # Every minute
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            command: ["sh", "-c", "date && echo 'Hello from CronJob!'"]
          restartPolicy: OnFailure
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
EOF

# Watch CronJob execution
kubectl get cronjob hello-cron -w
kubectl get jobs -l job-name=hello-cron

# Check job logs
kubectl logs job/$(kubectl get jobs -l job-name=hello-cron -o jsonpath='{.items[0].metadata.name}')

# Create backup CronJob
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: busybox
            command: ["sh", "-c", "
              echo 'Starting backup at $(date)'
              echo 'Backing up data...'
              sleep 30
              echo 'Backup completed at $(date)'
            "]
          restartPolicy: OnFailure
  concurrencyPolicy: Forbid  # Prevent overlapping jobs
  startingDeadlineSeconds: 300
EOF

# Test CronJob suspend/resume
kubectl patch cronjob hello-cron -p '{"spec":{"suspend":true}}'
kubectl get cronjob hello-cron
kubectl patch cronjob hello-cron -p '{"spec":{"suspend":false}}'
```

### Exercise 5.5: Advanced Container Patterns

**Goal**: Implement sophisticated multi-container patterns

**Files**: `resources/container-patterns/`

**Ambassador Pattern Example**:

```bash
# Deploy app with ambassador proxy
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ambassador-demo
spec:
  containers:
  # Main application
  - name: app
    image: nginx
    ports:
    - containerPort: 80
  
  # Ambassador proxy
  - name: ambassador
    image: haproxy:latest
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: haproxy-config
      mountPath: /usr/local/etc/haproxy
  
  volumes:
  - name: haproxy-config
    configMap:
      name: haproxy-config

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: haproxy-config
data:
  haproxy.cfg: |
    global
      daemon
    defaults
      mode http
      timeout connect 5000ms
      timeout client 50000ms
      timeout server 50000ms
    frontend ambassador
      bind *:8080
      default_backend app
    backend app
      server app1 127.0.0.1:80 check
EOF

# Test ambassador pattern
kubectl port-forward pod/ambassador-demo 8080:8080 &
curl http://localhost:8080
```

**Adapter Pattern Example**:

```bash
# Deploy app with adapter for monitoring
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: adapter-demo
spec:
  containers:
  # Main application (legacy format)
  - name: legacy-app
    image: busybox
    command: ["sh", "-c", "
      while true; do
        echo '$(date): LEGACY_LOG level=INFO message=Application_running'
        sleep 10
      done
    "]
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  
  # Adapter container (converts format)
  - name: log-adapter
    image: busybox
    command: ["sh", "-c", "
      tail -f /var/log/app.log | while read line; do
        echo '{\"timestamp\":\"'$(date -Iseconds)'\", \"level\":\"INFO\", \"message\":\"'$line'\"}'
      done
    "]
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  
  volumes:
  - name: log-volume
    emptyDir: {}
EOF

# Check adapted logs
kubectl logs adapter-demo -c log-adapter
```

## 🎯 Practice Challenges

### Challenge 5.1: Complete Monitoring Stack

**Location**: `resources/exercises/monitoring-stack/`

**Goal**: Deploy a production-ready monitoring infrastructure

**Architecture Requirements**:

1. **Prometheus (StatefulSet)**:
   - Persistent storage for metrics
   - High availability with multiple replicas
   - Service discovery configuration

2. **Node Exporter (DaemonSet)**:
   - Runs on every node
   - Collects node-level metrics
   - Secure configuration

3. **Grafana (Deployment)**:
   - Persistent storage for dashboards
   - LoadBalancer or Ingress access
   - Pre-configured data sources

4. **Alert Manager (StatefulSet)**:
   - Alert routing and notification
   - Persistent configuration
   - Integration with external services

**Your Deliverables**:

1. All Kubernetes manifests for the monitoring stack
2. Service discovery configuration for Prometheus
3. Pre-built Grafana dashboards
4. Alert rules and notification setup
5. High availability and backup strategies
6. Performance tuning and resource optimization

### Challenge 5.2: Data Processing Pipeline

**Location**: `resources/exercises/data-pipeline/`

**Goal**: Build a complete ETL pipeline using Jobs and CronJobs

**Pipeline Requirements**:

1. **Data Ingestion (CronJob)**:
   - Scheduled data collection from external APIs
   - Data validation and cleansing
   - Error handling and retry logic

2. **Data Processing (Jobs)**:
   - Parallel processing of large datasets
   - Transform data into analytics format
   - Quality checks and validation

3. **Report Generation (CronJob)**:
   - Daily/weekly/monthly reports
   - Export to different formats (PDF, CSV, JSON)
   - Email delivery and dashboard updates

4. **Data Archival (CronJob)**:
   - Cleanup old data
   - Archive to long-term storage
   - Compliance and retention policies

**Technical Requirements**:

- Fault tolerance and error recovery
- Monitoring and alerting for pipeline health
- Resource optimization for cost efficiency
- Data lineage and audit trails

### Challenge 5.3: System Services Infrastructure

**Location**: `resources/exercises/system-services/`

**Goal**: Deploy essential cluster services using appropriate workload types

**Services to Implement**:

1. **Log Collection (DaemonSet)**:
   - Fluentd/Fluent Bit on every node
   - Centralized log aggregation
   - Log parsing and enrichment

2. **Security Scanning (DaemonSet + CronJobs)**:
   - Continuous security scanning
   - Vulnerability assessments
   - Compliance reporting

3. **Backup Automation (CronJobs)**:
   - Automated database backups
   - Configuration backups
   - Cross-region replication

4. **Cluster Maintenance (CronJobs)**:
   - Certificate rotation
   - Resource cleanup
   - Performance optimization

**Architecture Considerations**:

- Resource management and node pressure
- Security and access controls
- Integration with external systems
- Disaster recovery procedures

## ❓ Knowledge Check Questions

### Workload Selection

1. **You need to collect logs from every node in your cluster. Which workload type should you use and why?**
2. **Compare running a database as a Deployment vs StatefulSet. What are the trade-offs?**
3. **When would you use a Job vs CronJob vs Deployment for data processing tasks?**

### Container Patterns

1. **Explain the difference between init containers and sidecar containers. Provide use cases for each.**
2. **How would you implement the ambassador pattern? What problems does it solve?**
3. **Design a logging architecture using sidecar containers. What are the benefits vs challenges?**

### Scaling and Management

1. **How does StatefulSet scaling differ from Deployment scaling? Why is this important?**
2. **What happens when a DaemonSet pod fails? How does Kubernetes handle recovery?**
3. **Design a strategy for handling failed Jobs in a batch processing pipeline.**

### Scenario-Based Questions

1. **Your application needs to process uploaded files. The processing can take 5-60 minutes per file. Design the workload architecture.**

2. **You need to run a monthly report that processes TB of data. The job occasionally fails due to memory issues. How would you design this?**

3. **Design a deployment strategy for a chat application that needs message persistence, real-time features, and background message processing.**

## 🚀 Real-world Project

**Project**: Microservices Platform with Complete Workload Ecosystem

**Context**: Build a comprehensive microservices platform using all workload types

**Application Architecture**:

- **User-Facing Services**: Web frontend, mobile API, admin dashboard
- **Business Services**: User management, product catalog, order processing
- **Data Services**: Multiple databases, caches, search engines
- **Background Services**: Email sending, image processing, analytics
- **System Services**: Logging, monitoring, security, backups

**Workload Design Requirements**:

1. **Stateless Services (Deployments)**:
   - Frontend applications with auto-scaling
   - API gateways with load balancing
   - Background job processors

2. **Stateful Services (StatefulSets)**:
   - Database clusters (PostgreSQL, MongoDB)
   - Message queues (RabbitMQ, Kafka)
   - Search engines (Elasticsearch)

3. **System Services (DaemonSets)**:
   - Log collection and forwarding
   - Monitoring agents and metrics collection
   - Security scanning and compliance

4. **Batch Processing (Jobs)**:
   - Data migration and ETL processes
   - Image and video processing
   - Machine learning model training

5. **Scheduled Tasks (CronJobs)**:
   - Database backups and maintenance
   - Report generation and delivery
   - Data cleanup and archival
   - Health checks and system maintenance

**Technical Requirements**:

1. **High Availability**: Multi-AZ deployment, fault tolerance
2. **Scalability**: Auto-scaling, resource optimization
3. **Security**: RBAC, network policies, secret management
4. **Monitoring**: Comprehensive observability stack
5. **Backup/Recovery**: Automated backup and disaster recovery
6. **Cost Optimization**: Resource right-sizing, spot instances

**Deliverables**:

1. **Complete architecture documentation** with workload justifications
2. **All Kubernetes manifests** for every component
3. **Deployment automation** with GitOps workflows
4. **Monitoring and alerting** setup for all workloads
5. **Disaster recovery procedures** and runbooks
6. **Cost analysis** and optimization recommendations
7. **Security audit** and compliance documentation

**Advanced Features**:

- Implement custom operators for complex applications
- Add service mesh for advanced traffic management
- Create automated testing pipelines
- Implement blue-green deployments for critical services
- Add machine learning workflows with GPU scheduling

## 🔍 Troubleshooting Guide

### Workload Issues Diagnostic Tree

```
Workload Not Behaving as Expected?
├── DaemonSet Issues
│   ├── Pods not on all nodes?
│   │   ├── Check node selectors/taints
│   │   ├── Verify tolerations
│   │   └── Check resource availability
│   └── Updates failing?
│       ├── Check rolling update strategy
│       └── Verify image availability
├── StatefulSet Issues
│   ├── Pods not starting in order?
│   │   ├── Check PVC availability
│   │   ├── Verify storage class
│   │   └── Check previous pod status
│   └── Data not persisting?
│       ├── Check PVC binding
│       └── Verify mount points
├── Job Issues
│   ├── Job not completing?
│   │   ├── Check pod logs
│   │   ├── Verify resource limits
│   │   └── Check exit codes
│   └── Too many failures?
│       ├── Check backoffLimit
│       └── Fix underlying issues
└── CronJob Issues
    ├── Jobs not running?
    │   ├── Verify cron schedule syntax
    │   ├── Check timezone settings
    │   └── Verify startingDeadlineSeconds
    └── Jobs running concurrently?
        ├── Check concurrencyPolicy
        └── Adjust job duration
```

### Essential Debugging Commands

```bash
# DaemonSet debugging
kubectl get daemonset -o wide
kubectl describe daemonset <name>
kubectl get pods -l app=<daemonset-app> -o wide

# StatefulSet debugging
kubectl get statefulset
kubectl describe statefulset <name>
kubectl get pods -l app=<statefulset-app> --sort-by=.metadata.name

# Job debugging
kubectl get jobs
kubectl describe job <name>
kubectl logs job/<name>

# CronJob debugging
kubectl get cronjob
kubectl describe cronjob <name>
kubectl get jobs -l job-name=<cronjob-name>

# Container pattern debugging
kubectl describe pod <name>
kubectl logs <pod-name> -c <container-name>
kubectl exec -it <pod-name> -c <container-name> -- sh
```

### Common Issues and Solutions

| Problem | Symptoms | Investigation | Solution |
|---------|----------|---------------|----------|
| DaemonSet pods missing | Not on all nodes | Check node selectors, taints | Add tolerations, fix selectors |
| StatefulSet stuck | Pods not starting | Check PVC, storage class | Fix storage issues |
| Job never completes | Running forever | Check job logic, resource limits | Fix application code |
| CronJob not triggering | No jobs created | Check schedule syntax | Fix cron expression |
| Init container failing | Pod stuck in Init | Check init container logs | Fix init container logic |
| Sidecar not working | Main app can't access sidecar | Check volume mounts, networking | Fix shared resources |

## 📚 Additional Resources

### Official Documentation

- [DaemonSets](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

### Advanced Patterns

- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Sidecar Containers](https://kubernetes.io/docs/concepts/cluster-administration/logging/#sidecar-container-with-logging-agent)
- [Multi-Container Patterns](https://kubernetes.io/blog/2015/06/the-distributed-system-toolkit-patterns/)

### Scheduling and Resource Management

- [Assign Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)

### Batch Processing

- [Parallel Processing with Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/#parallel-jobs)
- [Work Queue Pattern](https://kubernetes.io/docs/tasks/job/coarse-parallel-processing-work-queue/)

## ✅ Module Completion Checklist

Before moving to the next module, ensure you can:

- [ ] Choose the appropriate workload type for different use cases
- [ ] Deploy and manage DaemonSets for node-level services
- [ ] Configure StatefulSets for stateful applications with persistent storage
- [ ] Design and implement various Job patterns for batch processing
- [ ] Schedule tasks using CronJobs with proper concurrency control
- [ ] Implement advanced container patterns (init, sidecar, ambassador, adapter)
- [ ] Troubleshoot workload issues using systematic approaches
- [ ] Design complex multi-workload architectures
- [ ] Complete the microservices platform project successfully

## ➡️ Next Module

Ready to continue? Proceed to **[Module 6: Observability and Debugging](../Module-06-Observability-Debugging/README.md)** where you'll master:

- Centralized logging strategies
- Metrics collection and monitoring
- Health checks and probes
- Application debugging in Kubernetes
- Performance optimization and troubleshooting
