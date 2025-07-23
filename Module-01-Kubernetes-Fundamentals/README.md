# Module 1: Kubernetes Fundamentals

## 🎯 Learning Objectives

- Understand the difference between containers and VMs
- Learn what Kubernetes is and why it exists
- Master basic Kubernetes resources: Pod, Deployment, Service, ConfigMap
- Use essential kubectl commands confidently

## 📁 Module Structure

```txt
Module-01-Kubernetes-Fundamentals/
├── README.md (this file)
└── resources/
    ├── my-first-pod.yaml
    ├── nginx-deployment.yaml
    ├── nginx-service.yaml
    ├── app-config.yaml
    ├── pod-with-config.yaml
    └── exercises/
        ├── challenge-1/
        │   ├── deployment.yaml
        │   ├── service.yaml
        │   └── configmap.yaml
        └── challenge-2/
            ├── broken-pod.yaml
            ├── broken-service.yaml
            └── broken-deployment.yaml
```

## 📖 Theory

### Containers vs Virtual Machines

| Virtual Machines | Containers |
|------------------|------------|
| Full OS per VM | Share host OS kernel |
| GB of RAM usage | MB of RAM usage |
| Minutes to start | Seconds to start |
| Better isolation | Process-level isolation |
| More overhead | Lightweight |

### What is Kubernetes?

**The Problem Kubernetes Solves**:

- Managing hundreds of containers manually is impossible
- Ensuring high availability and automatic scaling
- Service discovery and load balancing
- Rolling updates without downtime
- Resource management across multiple servers

**Kubernetes Solution**:

- **Container Orchestration**: Automates deployment, scaling, and management
- **Declarative Configuration**: You describe desired state, K8s maintains it
- **Self-healing**: Automatically replaces failed containers
- **Load Balancing**: Distributes traffic across healthy instances

### Core Resources Overview

| Resource | Purpose | Example Use |
|----------|---------|-------------|
| **Pod** | Smallest deployable unit | Single container or tightly coupled containers |
| **Deployment** | Manages replica sets of pods | Web servers, APIs, stateless applications |
| **Service** | Provides stable networking | Load balancing, service discovery |
| **ConfigMap** | Stores configuration data | Environment variables, config files |

## 🔧 Essential kubectl Commands

### Cluster Information

```bash
kubectl cluster-info              # Show cluster information
kubectl get nodes                 # List all nodes
kubectl get namespaces            # List all namespaces
```

### Resource Management

```bash
kubectl get pods                  # List pods in current namespace
kubectl get pods -A               # List pods in all namespaces
kubectl get deployments          # List deployments
kubectl get services              # List services
kubectl get configmaps           # List config maps
```

### Detailed Information

```bash
kubectl describe pod <pod-name>           # Detailed pod information
kubectl describe deployment <dep-name>   # Detailed deployment information
kubectl get pods -o wide                 # More details in table format
kubectl get pods -o yaml                 # Full YAML output
```

### Logs and Debugging

```bash
kubectl logs <pod-name>                   # Show pod logs
kubectl logs -f <pod-name>                # Follow logs in real-time
kubectl logs <pod-name> -c <container>    # Logs from specific container
kubectl exec -it <pod-name> -- /bin/bash  # Shell into container
```

### Resource Creation and Management

```bash
kubectl apply -f <file.yaml>      # Create/update resources from file
kubectl delete -f <file.yaml>     # Delete resources from file
kubectl delete pod <pod-name>     # Delete specific pod
kubectl scale deployment <name> --replicas=5  # Scale deployment
```

## 🛠️ Hands-on Exercises

### Prerequisites Setup

1. **Install kubectl**: Follow [official installation guide](https://kubernetes.io/docs/tasks/tools/)
2. **Install minikube**: `brew install minikube` (macOS) or follow [minikube installation](https://minikube.sigs.k8s.io/docs/start/)
3. **Start cluster**: `minikube start`
4. **Verify**: `kubectl get nodes`

### Exercise 1.1: Your First Pod

**Goal**: Create and explore a simple pod

**Files**: `resources/my-first-pod.yaml`

**Steps**:

```bash
# Navigate to module directory
cd Module-01-Kubernetes-Fundamentals/

# Create the pod
kubectl apply -f resources/my-first-pod.yaml

# Check if it's running
kubectl get pods

# Get detailed information
kubectl describe pod nginx-pod

# Check logs
kubectl logs nginx-pod

# Clean up
kubectl delete -f resources/my-first-pod.yaml
```

**Questions to Answer**:

1. What state was the pod in initially?
2. How long did it take to reach "Running" state?
3. What information does `kubectl describe` show that `kubectl get` doesn't?

### Exercise 1.2: Your First Deployment

**Goal**: Create a deployment that manages multiple pod replicas

**Files**: `resources/nginx-deployment.yaml`

**Steps**:

```bash
# Create deployment
kubectl apply -f resources/nginx-deployment.yaml

# Watch pods being created
kubectl get pods -w

# Check deployment status
kubectl get deployments
kubectl describe deployment nginx-deployment

# Scale the deployment
kubectl scale deployment nginx-deployment --replicas=5
kubectl get pods

# Scale back down
kubectl scale deployment nginx-deployment --replicas=3
```

**Experiment**:

- Delete one pod: `kubectl delete pod <pod-name>`
- Watch what happens: `kubectl get pods -w`
- **Question**: Why did Kubernetes create a new pod automatically?

### Exercise 1.3: Your First Service

**Goal**: Expose your deployment with a service

**Files**: `resources/nginx-service.yaml`

**Prerequisites**: Ensure nginx-deployment from Exercise 1.2 is running

**Steps**:

```bash
# Create service
kubectl apply -f resources/nginx-service.yaml

# Check service
kubectl get services
kubectl describe service nginx-service

# Test connectivity from inside cluster
kubectl run test-pod --image=busybox --rm -it -- sh
# Inside the test pod, run:
wget -qO- nginx-service
exit
```

**What You Should See**: HTML content from nginx server

### Exercise 1.4: Your First ConfigMap

**Goal**: Store configuration data separately from your application

**Files**: `resources/app-config.yaml`, `resources/pod-with-config.yaml`

**Steps**:

```bash
# Create ConfigMap
kubectl apply -f resources/app-config.yaml

# View ConfigMap content
kubectl get configmap app-config -o yaml

# Create pod that uses ConfigMap
kubectl apply -f resources/pod-with-config.yaml

# Check environment variables in the pod
kubectl exec app-pod -- env | grep -E "(DATABASE_URL|DEBUG_MODE)"

# Clean up
kubectl delete -f resources/pod-with-config.yaml
kubectl delete -f resources/app-config.yaml
```

## 🎯 Practice Challenges

### Challenge 1: Complete Application Setup

**Location**: `resources/exercises/challenge-1/`

**Goal**: Create a complete setup with proper labeling and organization

**Requirements**:

1. Deployment running nginx with 2 replicas
2. Service exposing the deployment  
3. ConfigMap with custom configuration
4. Consistent labels across all resources
5. Everything should work together seamlessly

**Success Criteria**:

- All pods are running
- Service correctly routes to pods
- Configuration is loaded from ConfigMap
- You can access the application from a test pod

### Challenge 2: Troubleshooting Practice

**Location**: `resources/exercises/challenge-2/`

**Goal**: Debug intentionally broken resources

**What's Provided**:

- `broken-pod.yaml` - Pod with incorrect image name
- `broken-service.yaml` - Service with wrong selector
- `broken-deployment.yaml` - Deployment with invalid YAML

**Your Task**:

1. Try to apply each broken resource
2. Use debugging commands to identify issues
3. Fix each resource and apply successfully

**Debugging Commands to Practice**:

```bash
kubectl get events                                    # Cluster events
kubectl describe <resource-type> <resource-name>     # Detailed resource info
kubectl logs <pod-name>                             # Container logs
```

## ❓ Knowledge Check Questions

### Conceptual Understanding

1. What are three main advantages containers have over VMs for microservices architecture?
2. Explain why you can't run containers directly in production without an orchestrator like Kubernetes.
3. What happens when you delete a pod that's managed by a deployment? Why?
4. How does Kubernetes ensure your application stays running even if nodes fail?

### Practical Questions

1. What's the difference between `kubectl apply` and `kubectl create`?
2. How do you check if a pod is ready to serve traffic?
3. What command would you use to see real-time logs from a pod?
4. How can you update application configuration without rebuilding container images?

### Scenario-Based

1. **Scenario**: Your pod is stuck in "Pending" state for 5 minutes.
   - What are three possible causes?
   - What commands would you use to investigate?

2. **Scenario**: You need to expose a web application so other services in the cluster can access it.
   - What Kubernetes resources do you need?
   - What type of service would you use?

3. **Scenario**: You need to temporarily scale down an application for maintenance.
   - What command would you use?
   - How would you scale it back up?

## 🚀 Real-world Scenario

**Context**: You're a DevOps engineer at a startup. The development team has created a simple web application that needs to be deployed to Kubernetes.

**Application Requirements**:

- Web server should run 3 replicas for high availability
- Application reads database connection string from environment variables
- Other services in the cluster need to communicate with this application
- Configuration should be easily changeable without code changes
- You need to monitor application health through logs

**Your Deliverables**:

1. All necessary Kubernetes YAML files
2. Deployment documentation with step-by-step instructions
3. Troubleshooting guide for common issues
4. Commands to verify everything is working correctly

**Bonus Points**:

- Add resource limits to prevent one application from consuming all cluster resources
- Include health checks to ensure Kubernetes knows when your app is ready
- Create a simple monitoring setup to track application performance

## 🔍 Troubleshooting Guide

### Common Issues and Solutions

| Problem | Symptoms | Investigation | Solution |
|---------|----------|---------------|----------|
| Pod stuck in Pending | `kubectl get pods` shows Pending | `kubectl describe pod <name>` | Check resource constraints, node capacity |
| Pod CrashLoopBackOff | Pod restarts continuously | `kubectl logs <pod-name>` | Fix application errors, check liveness probes |
| Service not accessible | Can't reach application | `kubectl get endpoints` | Verify service selector matches pod labels |
| Image pull errors | Pod shows ImagePullBackOff | `kubectl describe pod <name>` | Check image name, registry access |

### Essential Debugging Workflow

1. **Check resource status**: `kubectl get <resource-type>`
2. **Get detailed info**: `kubectl describe <resource-type> <name>`
3. **Check logs**: `kubectl logs <pod-name>`
4. **View cluster events**: `kubectl get events --sort-by=.metadata.creationTimestamp`

## 📚 Additional Resources

- [Official Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [Play with Kubernetes](https://labs.play-with-k8s.com/) - Free browser-based learning environment

## ✅ Module Completion Checklist

Before moving to the next module, ensure you can:

- [ ] Explain the difference between containers and VMs
- [ ] Describe what problems Kubernetes solves
- [ ] Create and manage Pods using YAML files
- [ ] Deploy applications using Deployments
- [ ] Expose applications using Services
- [ ] Store configuration using ConfigMaps
- [ ] Use essential kubectl commands confidently
- [ ] Debug common issues using kubectl describe and logs
- [ ] Complete both practice challenges successfully

## ➡️ Next Module

Ready for more? Continue to **[Module 2: Pods and YAML Deep Dive](../Module-02-Pods-YAML-Deep-Dive/README.md)** where you'll learn:

- Pod anatomy and lifecycle in detail
- YAML structure and best practices
- Advanced deployment strategies
- Rolling updates and rollbacks
