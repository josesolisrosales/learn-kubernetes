# Module 2: Pods and YAML Deep Dive

## 🎯 Learning Objectives
- Master Pod anatomy: containers, volumes, and networking
- Understand Pod lifecycle states and transitions
- Deep dive into YAML structure: metadata, spec, and status
- Implement advanced deployment strategies with rolling updates and rollbacks
- Write Kubernetes manifests from scratch with confidence

## 📁 Module Structure
```
Module-02-Pods-YAML-Deep-Dive/
├── README.md (this file)
└── resources/
    ├── pod-anatomy/
    │   ├── multi-container-pod.yaml
    │   ├── pod-with-volumes.yaml
    │   ├── init-container-example.yaml
    │   └── sidecar-pattern.yaml
    ├── lifecycle-examples/
    │   ├── pod-lifecycle-demo.yaml
    │   ├── failing-pod.yaml
    │   └── graceful-shutdown.yaml
    ├── yaml-structure/
    │   ├── basic-structure.yaml
    │   ├── metadata-examples.yaml
    │   ├── spec-deep-dive.yaml
    │   └── annotations-labels.yaml
    ├── deployment-strategies/
    │   ├── rolling-update-demo.yaml
    │   ├── recreate-strategy.yaml
    │   └── rollback-practice.yaml
    └── exercises/
        ├── build-from-scratch/
        │   ├── requirements.md
        │   └── solution/
        ├── pod-debugging/
        │   ├── debug-scenarios.yaml
        │   └── troubleshooting-guide.md
        └── advanced-patterns/
            ├── ambassador-pattern.yaml
            ├── adapter-pattern.yaml
            └── multi-tier-app.yaml
```

## 📖 Theory

### Pod Anatomy Deep Dive

#### What is a Pod Really?
A Pod is the smallest deployable unit in Kubernetes, but it's much more than just a container wrapper:

- **Shared Network**: All containers in a pod share the same IP address and port space
- **Shared Storage**: Containers can share volumes for data exchange
- **Shared Lifecycle**: All containers start and stop together
- **Atomic Unit**: The entire pod is scheduled to the same node

#### Pod Components

```
┌─────────────────────────────────────────┐
│                  Pod                    │
│  ┌─────────────┐    ┌─────────────┐     │
│  │ Container 1 │    │ Container 2 │     │
│  │             │    │             │     │
│  └─────────────┘    └─────────────┘     │
│           │               │             │
│  ┌─────────────────────────────────┐    │
│  │        Shared Network           │    │
│  │      (localhost, ports)         │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │       Shared Volumes            │    │
│  │    (emptyDir, configMap, etc)   │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### Pod Lifecycle States

| State | Description | What's Happening |
|-------|-------------|------------------|
| **Pending** | Pod accepted by cluster but not running | Scheduling, image pulling, container creation |
| **Running** | At least one container is running | Normal operation |
| **Succeeded** | All containers terminated successfully | Completed jobs/tasks |
| **Failed** | All containers terminated, at least one failed | Application errors, crashes |
| **Unknown** | Pod state cannot be determined | Node communication issues |

#### Lifecycle Transitions
```
Pending → Running → Succeeded/Failed
   ↓         ↓
Unknown ← Unknown
```

#### Container States Within Pods
- **Waiting**: Container not running (pulling image, waiting for dependencies)
- **Running**: Container executing normally
- **Terminated**: Container finished execution (success or failure)

### YAML Structure Deep Dive

Every Kubernetes resource follows the same basic structure:

```yaml
apiVersion: <api-group>/<version>  # Which API to use
kind: <resource-type>              # What type of resource
metadata:                          # Information about the resource
  name: <resource-name>
  namespace: <namespace>
  labels: {}
  annotations: {}
spec:                             # Desired state specification
  # Resource-specific configuration
status:                           # Current state (managed by Kubernetes)
  # Runtime information
```

#### Metadata Deep Dive

**Labels vs Annotations**:

| Labels | Annotations |
|--------|-------------|
| Key-value pairs for selection | Key-value pairs for metadata |
| Used by selectors and queries | Used for tools and libraries |
| Limited character set | More flexible format |
| `app: frontend` | `deployment.kubernetes.io/revision: "1"` |

**Best Practices**:
- Use consistent labeling strategy
- Include app, version, component, part-of
- Use annotations for build info, contact details, documentation links

### Deployment Strategies

#### Rolling Updates (Default)
- **How it works**: Gradually replace old pods with new ones
- **Advantages**: Zero downtime, gradual rollout
- **Use cases**: Most web applications, APIs

#### Recreate Strategy
- **How it works**: Kill all old pods, then create new ones
- **Advantages**: Simple, ensures clean state
- **Use cases**: Applications that can't run multiple versions

#### Rollback Capabilities
Kubernetes maintains deployment history for easy rollbacks:
```bash
kubectl rollout history deployment/my-app
kubectl rollout undo deployment/my-app
kubectl rollout undo deployment/my-app --to-revision=2
```

## 🛠️ Hands-on Exercises

### Prerequisites
- Completed Module 1
- Running Kubernetes cluster (minikube/kind)
- kubectl configured and working

### Exercise 2.1: Pod Anatomy Exploration
**Goal**: Understand how containers within pods interact

**Files**: `resources/pod-anatomy/multi-container-pod.yaml`

**Steps**:
```bash
# Navigate to module directory
cd Module-02-Pods-YAML-Deep-Dive/

# Create multi-container pod
kubectl apply -f resources/pod-anatomy/multi-container-pod.yaml

# Examine the pod
kubectl get pods
kubectl describe pod multi-container-demo

# Test shared networking
kubectl exec -it multi-container-demo -c main-app -- curl localhost:8080
kubectl exec -it multi-container-demo -c sidecar -- netstat -tlnp

# Check shared filesystem
kubectl exec -it multi-container-demo -c main-app -- ls -la /shared-data
kubectl exec -it multi-container-demo -c sidecar -- ls -la /shared-data
```

**Questions to Explore**:
1. Can containers in the same pod communicate via localhost?
2. How do containers share files?
3. What happens if one container crashes?

### Exercise 2.2: Pod Lifecycle Observation
**Goal**: Watch pods transition through lifecycle states

**Files**: `resources/lifecycle-examples/pod-lifecycle-demo.yaml`

**Steps**:
```bash
# Start watching pod states
kubectl get pods -w &

# Create pod that goes through different states
kubectl apply -f resources/lifecycle-examples/pod-lifecycle-demo.yaml

# Watch the transitions: Pending → Running → Succeeded
# Stop the watch with Ctrl+C

# Examine lifecycle events
kubectl describe pod lifecycle-demo
kubectl get events --sort-by=.metadata.creationTimestamp
```

**Advanced**: Try the failing pod example to see Failed state:
```bash
kubectl apply -f resources/lifecycle-examples/failing-pod.yaml
kubectl describe pod failing-pod
kubectl logs failing-pod
```

### Exercise 2.3: YAML Structure Mastery
**Goal**: Build complex YAML from understanding, not copying

**Files**: `resources/yaml-structure/` directory

**Step 1 - Analyze Structure**:
```bash
# Examine different YAML examples
kubectl apply -f resources/yaml-structure/basic-structure.yaml
kubectl get pod yaml-demo -o yaml

# Pay attention to:
# - apiVersion and kind
# - metadata structure
# - spec vs status sections
```

**Step 2 - Practice with Metadata**:
```bash
# Apply examples with rich metadata
kubectl apply -f resources/yaml-structure/metadata-examples.yaml

# Query using labels
kubectl get pods -l app=demo
kubectl get pods -l environment=development
kubectl get pods -l 'tier in (frontend,backend)'

# View annotations
kubectl get pod metadata-demo -o jsonpath='{.metadata.annotations}'
```

**Challenge**: Write a pod YAML from scratch without looking at examples. Include:
- Proper metadata with labels and annotations
- Container with resource limits
- Environment variables
- Health checks

### Exercise 2.4: Rolling Updates and Rollbacks
**Goal**: Master deployment strategies and version management

**Files**: `resources/deployment-strategies/rolling-update-demo.yaml`

**Step 1 - Initial Deployment**:
```bash
# Deploy initial version
kubectl apply -f resources/deployment-strategies/rolling-update-demo.yaml

# Check deployment status
kubectl get deployments
kubectl get replicasets
kubectl get pods

# Check rollout status
kubectl rollout status deployment/rolling-demo
```

**Step 2 - Perform Rolling Update**:
```bash
# Update the image (simulate new version)
kubectl set image deployment/rolling-demo app=nginx:1.22

# Watch the rolling update
kubectl get pods -w

# Check rollout history
kubectl rollout history deployment/rolling-demo
```

**Step 3 - Practice Rollback**:
```bash
# Rollback to previous version
kubectl rollout undo deployment/rolling-demo

# Watch the rollback
kubectl get pods -w

# Verify rollback
kubectl rollout history deployment/rolling-demo
kubectl describe deployment rolling-demo
```

**Advanced Scenarios**:
```bash
# Pause a rollout
kubectl rollout pause deployment/rolling-demo
kubectl set image deployment/rolling-demo app=nginx:1.23
# Note: Update is paused

# Resume rollout
kubectl rollout resume deployment/rolling-demo
```

### Exercise 2.5: Multi-Container Patterns
**Goal**: Implement common multi-container design patterns

**Files**: `resources/pod-anatomy/` - sidecar, init container examples

**Sidecar Pattern**:
```bash
# Deploy sidecar example (log collector + web app)
kubectl apply -f resources/pod-anatomy/sidecar-pattern.yaml

# Verify both containers are running
kubectl get pods sidecar-demo
kubectl describe pod sidecar-demo

# Check logs from both containers
kubectl logs sidecar-demo -c web-app
kubectl logs sidecar-demo -c log-collector
```

**Init Container Pattern**:
```bash
# Deploy with init container (database setup + app)
kubectl apply -f resources/pod-anatomy/init-container-example.yaml

# Watch init container complete before main container starts
kubectl get pods -w

# Examine the sequence
kubectl describe pod init-demo
kubectl logs init-demo -c init-db
kubectl logs init-demo -c main-app
```

## 🎯 Practice Challenges

### Challenge 2.1: Build Complete App from Scratch
**Location**: `resources/exercises/build-from-scratch/`

**Scenario**: You're tasked with deploying a web application with the following requirements:

**Requirements** (see `requirements.md`):
- Frontend web server (nginx) with custom configuration
- Backend API simulator (can use busybox with custom script)
- Shared logging sidecar container
- All configuration stored in ConfigMaps
- Proper labeling and annotations for a production environment
- Rolling update strategy with health checks
- Resource limits appropriate for development environment

**Your Deliverables**:
1. All YAML manifests written from scratch
2. Documentation explaining your design decisions
3. Test procedures to verify everything works
4. Rollback plan in case of issues

**Success Criteria**:
- All pods running and healthy
- Frontend can communicate with backend
- Logs are being collected by sidecar
- Rolling updates work without downtime
- All resources properly labeled and organized

### Challenge 2.2: Pod Debugging Scenarios
**Location**: `resources/exercises/pod-debugging/`

**Goal**: Become proficient at diagnosing and fixing pod issues

**Scenarios**:
1. **Image Pull Issues**: Pod stuck in ImagePullBackOff
2. **Resource Constraints**: Pod pending due to insufficient resources
3. **Configuration Errors**: Pod crashing due to missing ConfigMap
4. **Network Issues**: Containers can't communicate
5. **Storage Problems**: Volume mount failures

**Your Task**:
- Use systematic debugging approach
- Document your investigation process
- Fix each issue and verify resolution
- Create prevention strategies

### Challenge 2.3: Advanced Container Patterns
**Location**: `resources/exercises/advanced-patterns/`

**Implement These Patterns**:

1. **Ambassador Pattern**: Proxy container that handles external service connections
2. **Adapter Pattern**: Container that transforms application output for monitoring
3. **Multi-Tier Application**: Complete 3-tier app with proper separation

**Requirements**:
- Use appropriate container patterns
- Implement proper service discovery
- Add monitoring and health checks
- Document the architecture

## ❓ Knowledge Check Questions

### Pod Anatomy
1. **Why would you put multiple containers in a single pod vs. separate pods?**
2. **How do containers in a pod share resources? What are the implications?**
3. **When would you use an init container vs. a sidecar container?**

### Lifecycle Management
1. **A pod is stuck in Pending state. What are the top 3 reasons and how would you investigate?**
2. **Explain the difference between a container restart and a pod restart.**
3. **How does Kubernetes decide when to restart a container vs. recreate a pod?**

### YAML Mastery
1. **What's the difference between labels and annotations? Give 3 examples of each.**
2. **Why do some fields appear in both spec and status sections?**
3. **How would you structure labels for a microservices architecture with multiple environments?**

### Deployment Strategies
1. **Compare rolling updates vs. recreate strategy. When would you use each?**
2. **What happens during a rollback? How does Kubernetes manage the transition?**
3. **How would you implement blue-green deployments using Kubernetes primitives?**

### Scenario-Based Questions
1. **Your application needs to process files that arrive in a specific directory. How would you design this using pods and containers?**

2. **You need to deploy an application that requires a database to be ready before starting. Design the pod structure.**

3. **Your monitoring team needs access to application logs in real-time, but the application writes logs to files. How would you solve this?**

## 🚀 Real-world Project

**Project**: Microservices Blog Platform

**Context**: Build a complete blog platform with microservices architecture

**Architecture Requirements**:
- **Frontend**: Static web server (nginx) serving React app
- **API Gateway**: Proxy/router to backend services
- **Blog Service**: Handles blog posts (simulated with simple API)
- **User Service**: Handles authentication (simulated)
- **Database**: Persistent storage (we'll use ConfigMap for now)
- **Logging**: Centralized log collection
- **Monitoring**: Health check endpoints

**Technical Requirements**:
1. **Multi-container patterns** where appropriate
2. **Rolling updates** with zero downtime
3. **Health checks** for all services
4. **Configuration management** with ConfigMaps
5. **Proper labeling** for service discovery
6. **Resource management** with limits and requests
7. **Documentation** of the entire system

**Deliverables**:
1. Complete YAML manifests for all components
2. Architecture diagram showing container relationships
3. Deployment guide with step-by-step instructions
4. Troubleshooting runbook
5. Testing procedures to verify functionality
6. Performance considerations and resource planning

**Bonus Points**:
- Implement graceful shutdown procedures
- Add custom health check endpoints
- Create monitoring dashboards (documentation only)
- Design disaster recovery procedures

## 🔍 Troubleshooting Guide

### Pod Issues Diagnostic Tree

```
Pod Not Running?
├── Check Status: kubectl get pods
├── Pending?
│   ├── Resource Issues?
│   │   ├── kubectl describe node
│   │   └── Check CPU/Memory requests
│   ├── Scheduling Issues?
│   │   ├── Node selectors/taints
│   │   └── Pod anti-affinity rules
│   └── Image Issues?
│       ├── Image pull secrets
│       └── Registry accessibility
├── Running but Unhealthy?
│   ├── Check logs: kubectl logs <pod>
│   ├── Examine events: kubectl describe pod <pod>
│   └── Test health checks
└── CrashLoopBackOff?
    ├── Application errors in logs
    ├── Resource limits too low
    └── Configuration issues
```

### Essential Debugging Commands

```bash
# Pod investigation
kubectl get pods -o wide
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous  # Previous container instance

# Multi-container debugging
kubectl logs <pod-name> -c <container-name>
kubectl exec -it <pod-name> -c <container-name> -- sh

# Events and cluster state
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl top pods  # Resource usage (requires metrics server)

# Deployment debugging
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl get replicasets
```

### Common Issues and Solutions

| Problem | Symptoms | Investigation | Solution |
|---------|----------|---------------|----------|
| ImagePullBackOff | Pod stuck in waiting | `kubectl describe pod` | Fix image name, check registry access |
| CrashLoopBackOff | Pod restarting continuously | `kubectl logs` | Fix application errors, adjust resources |
| Pending pods | Pod not scheduled | `kubectl describe pod` | Check resource requests, node capacity |
| Service not accessible | Can't reach application | `kubectl get endpoints` | Verify service selector matches pod labels |

## 📚 Additional Resources

### Official Documentation
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Managing Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

### Best Practices
- [Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

### Tools and Utilities
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [YAML Validator](https://codebeautify.org/yaml-validator)

## ✅ Module Completion Checklist

Before moving to the next module, ensure you can:

- [ ] Explain pod anatomy and when to use multi-container pods
- [ ] Identify and troubleshoot pod lifecycle issues
- [ ] Write complex YAML manifests from scratch
- [ ] Implement effective labeling and annotation strategies
- [ ] Perform rolling updates and rollbacks confidently
- [ ] Debug pod issues using systematic approaches
- [ ] Design multi-container patterns for real-world scenarios
- [ ] Complete the microservices project successfully

## ➡️ Next Module

Ready to continue? Proceed to **[Module 3: Services and Networking](../Module-03-Services-Networking/README.md)** where you'll master:
- Kubernetes networking concepts
- Service types and use cases
- Ingress controllers and routing
- DNS and service discovery
- Network troubleshooting
