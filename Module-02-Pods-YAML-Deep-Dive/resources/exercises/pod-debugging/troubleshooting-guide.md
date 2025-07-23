# Pod Debugging and Troubleshooting Guide

## 🎯 Overview
This comprehensive guide provides systematic approaches to diagnosing and resolving common Kubernetes pod issues. Use this as your go-to reference for troubleshooting pod problems in any Kubernetes environment.

## 🔍 Diagnostic Methodology

### The PERC Method
Use this systematic approach for any pod issue:

1. **P**od Status - Check the current state
2. **E**vents - Examine cluster events
3. **R**esources - Verify resource availability
4. **C**onfiguration - Validate configuration

## 📊 Pod Status Reference

### Pod Phases
| Phase | Description | Common Causes | Next Steps |
|-------|-------------|---------------|------------|
| **Pending** | Pod accepted but not running | Resource constraints, scheduling issues, image pull problems | Check node resources, scheduling constraints |
| **Running** | At least one container is running | Normal operation | Monitor health checks |
| **Succeeded** | All containers terminated successfully | Completed job/task | Normal for jobs and completed tasks |
| **Failed** | All containers terminated, at least one failed | Application errors, crashes | Check logs and container status |
| **Unknown** | Pod state cannot be determined | Node communication issues | Check node status and network |

### Container States
| State | Description | Troubleshooting Actions |
|-------|-------------|------------------------|
| **Waiting** | Container not yet running | Check image availability, resource requests |
| **Running** | Container executing normally | Monitor health checks and logs |
| **Terminated** | Container finished execution | Check exit code and termination reason |

## 🛠️ Essential Diagnostic Commands

### Quick Status Check
```bash
# Get pod overview
kubectl get pods -o wide

# Detailed pod information
kubectl describe pod <pod-name>

# Check pod logs
kubectl logs <pod-name>

# Check previous container logs (if restarted)
kubectl logs <pod-name> --previous

# Multi-container pod logs
kubectl logs <pod-name> -c <container-name>

# Follow logs in real-time
kubectl logs <pod-name> -f

# Get pod YAML
kubectl get pod <pod-name> -o yaml
```

### Resource Investigation
```bash
# Check node resources
kubectl top nodes

# Check pod resource usage
kubectl top pods

# Check resource quotas
kubectl describe resourcequota

# Check limit ranges
kubectl describe limitrange

# Node capacity and allocation
kubectl describe node <node-name>
```

### Event Analysis
```bash
# Get recent events
kubectl get events --sort-by=.metadata.creationTimestamp

# Filter events for specific pod
kubectl get events --field-selector involvedObject.name=<pod-name>

# Get events in different formats
kubectl get events -o wide
kubectl get events -o yaml
```

## 🚨 Common Issues and Solutions

### 1. ImagePullBackOff / ErrImagePull

**Symptoms:**
- Pod stuck in `Pending` or `ErrImagePull` state
- Events show image pull failures

**Diagnostic Commands:**
```bash
kubectl describe pod <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>
```

**Common Causes & Solutions:**

#### Incorrect Image Name
```bash
# Check image name in pod spec
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].image}'

# Verify image exists in registry
docker pull <image-name>

# Fix: Update deployment with correct image
kubectl set image deployment/<deployment-name> <container>=<correct-image>
```

#### Private Registry Authentication
```bash
# Check if image pull secret exists
kubectl get secrets

# Create image pull secret
kubectl create secret docker-registry <secret-name> \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email>

# Add secret to deployment
kubectl patch deployment <deployment-name> -p \
'{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"<secret-name>"}]}}}}'
```

#### Network/Registry Issues
```bash
# Test registry connectivity from node
kubectl run test-registry --image=busybox --rm -it -- wget -O- <registry-url>

# Check DNS resolution
kubectl run test-dns --image=busybox --rm -it -- nslookup <registry-domain>

# Check corporate firewalls/proxies
kubectl get nodes -o wide  # Get node IPs
# SSH to node and test connectivity
```

### 2. CrashLoopBackOff

**Symptoms:**
- Pod restarts continuously
- Container exit code non-zero
- Restart count keeps increasing

**Diagnostic Commands:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[*].restartCount}'
```

**Common Causes & Solutions:**

#### Application Startup Errors
```bash
# Check application logs
kubectl logs <pod-name> --previous

# Examine exit code
kubectl get pod <pod-name> -o yaml | grep -A5 lastState

# Fix: Common startup issues
# - Incorrect command/args
# - Missing environment variables
# - Configuration file errors
# - Port binding issues
```

**Example Fix:**
```yaml
# Incorrect
containers:
- name: app
  image: nginx
  command: ["/usr/sbin/nginx"]
  args: ["-g", "daemon off;"]

# Correct
containers:
- name: app
  image: nginx
  command: ["/usr/sbin/nginx"]
  args: ["-g", "daemon off;"]
```

#### Resource Limits Too Low
```bash
# Check resource usage
kubectl top pod <pod-name>

# Check OOMKilled status
kubectl describe pod <pod-name> | grep -A5 "Last State"

# Fix: Increase memory limits
kubectl patch deployment <deployment-name> -p \
'{"spec":{"template":{"spec":{"containers":[{"name":"<container>","resources":{"limits":{"memory":"512Mi"}}}]}}}}'
```

#### Failed Health Checks
```bash
# Check health check configuration
kubectl get pod <pod-name> -o yaml | grep -A10 -B5 "probe"

# Test health check manually
kubectl exec <pod-name> -- curl http://localhost:8080/health

# Fix: Adjust probe parameters
kubectl patch deployment <deployment-name> -p \
'{"spec":{"template":{"spec":{"containers":[{"name":"<container>","readinessProbe":{"failureThreshold":5,"initialDelaySeconds":30}}]}}}}'
```

### 3. Pending Pods

**Symptoms:**
- Pod stuck in `Pending` state
- No containers started
- Scheduling issues

**Diagnostic Commands:**
```bash
kubectl describe pod <pod-name>
kubectl get nodes
kubectl describe node <node-name>
```

**Common Causes & Solutions:**

#### Insufficient Resources
```bash
# Check node capacity
kubectl top nodes

# Check resource requests vs capacity
kubectl describe node <node-name> | grep -A5 "Allocated resources"

# Fix: Reduce resource requests or add nodes
kubectl patch deployment <deployment-name> -p \
'{"spec":{"template":{"spec":{"containers":[{"name":"<container>","resources":{"requests":{"cpu":"100m","memory":"128Mi"}}}]}}}}'
```

#### Node Selector/Affinity Issues
```bash
# Check pod node selector
kubectl get pod <pod-name> -o yaml | grep -A5 nodeSelector

# Check node labels
kubectl get nodes --show-labels

# Fix: Update node selector or add labels to nodes
kubectl label node <node-name> <key>=<value>
```

#### Taints and Tolerations
```bash
# Check node taints
kubectl describe node <node-name> | grep Taints

# Check pod tolerations
kubectl get pod <pod-name> -o yaml | grep -A5 tolerations

# Fix: Add toleration to pod
kubectl patch deployment <deployment-name> -p \
'{"spec":{"template":{"spec":{"tolerations":[{"key":"<taint-key>","operator":"Equal","value":"<taint-value>","effect":"NoSchedule"}]}}}}'
```

### 4. Volume Mount Issues

**Symptoms:**
- Containers crash on startup
- Permission denied errors
- Missing files/directories

**Diagnostic Commands:**
```bash
kubectl describe pod <pod-name>
kubectl get pv,pvc
kubectl describe pvc <pvc-name>
```

**Common Causes & Solutions:**

#### PVC Not Bound
```bash
# Check PVC status
kubectl get pvc

# Check storage class
kubectl get storageclass

# Check PV availability
kubectl get pv

# Fix: Create PV or fix storage class
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: <pv-name>
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data
EOF
```

#### Permission Issues
```bash
# Check security context
kubectl get pod <pod-name> -o yaml | grep -A10 securityContext

# Fix: Set appropriate user/group
kubectl patch deployment <deployment-name> -p \
'{"spec":{"template":{"spec":{"securityContext":{"fsGroup":2000,"runAsUser":1000}}}}}'
```

#### ConfigMap/Secret Not Found
```bash
# Check if ConfigMap exists
kubectl get configmap <configmap-name>

# Check if Secret exists
kubectl get secret <secret-name>

# Create missing ConfigMap
kubectl create configmap <configmap-name> --from-file=<file-path>
```

## 🔧 Advanced Debugging Techniques

### Interactive Debugging
```bash
# Execute commands in running container
kubectl exec -it <pod-name> -- /bin/bash

# Copy files from pod
kubectl cp <pod-name>:<path> <local-path>

# Copy files to pod
kubectl cp <local-path> <pod-name>:<path>

# Port forward for local access
kubectl port-forward <pod-name> 8080:80
```

### Debug Container (Kubernetes 1.20+)
```bash
# Add debug container to running pod
kubectl debug <pod-name> -it --image=busybox --target=<container-name>

# Create debug pod with same spec
kubectl debug <pod-name> -it --image=busybox --copy-to=<debug-pod-name>
```

### Network Debugging
```bash
# Test DNS resolution
kubectl run dns-test --image=busybox --rm -it -- nslookup kubernetes.default

# Test service connectivity
kubectl run net-test --image=nicolaka/netshoot --rm -it -- curl <service-name>

# Check network policies
kubectl get networkpolicy
kubectl describe networkpolicy <policy-name>
```

## 📋 Troubleshooting Checklist

### Pre-Deployment Checklist
- [ ] YAML syntax is valid
- [ ] Image names are correct and accessible
- [ ] Resource requests are reasonable
- [ ] Required ConfigMaps/Secrets exist
- [ ] Node selectors/affinity rules are valid
- [ ] Security contexts are appropriate

### Pod Startup Issues
- [ ] Check pod status and phase
- [ ] Review events for error messages
- [ ] Verify image pull success
- [ ] Check resource availability
- [ ] Validate volume mounts
- [ ] Review security constraints

### Runtime Issues
- [ ] Check application logs
- [ ] Monitor resource usage
- [ ] Verify health check endpoints
- [ ] Test network connectivity
- [ ] Check persistent storage
- [ ] Review security policies

### Performance Issues
- [ ] Monitor CPU and memory usage
- [ ] Check I/O wait times
- [ ] Review network latency
- [ ] Analyze startup times
- [ ] Check resource limits
- [ ] Monitor garbage collection (if applicable)

## 🎯 Scenario-Based Troubleshooting

### Scenario 1: Web Application Won't Start
```
Symptoms:
- Pod in CrashLoopBackOff
- Logs show "bind: address already in use"
- Container restarts every 30 seconds
```

**Investigation Steps:**
```bash
# 1. Check logs
kubectl logs <pod-name> --previous

# 2. Check port configuration
kubectl get pod <pod-name> -o yaml | grep -A5 ports

# 3. Check for port conflicts
kubectl exec <pod-name> -- netstat -tlnp

# 4. Verify application configuration
kubectl describe configmap <config-name>
```

**Solution:**
```yaml
# Fix port binding issue
containers:
- name: web-app
  image: nginx
  ports:
  - containerPort: 8080  # Change from 80 if conflict exists
  env:
  - name: PORT
    value: "8080"
```

### Scenario 2: Database Connection Failures
```
Symptoms:
- Application logs show database connection errors
- Pods running but health checks failing
- Intermittent connection issues
```

**Investigation Steps:**
```bash
# 1. Test database connectivity
kubectl exec <app-pod> -- telnet <db-service> 5432

# 2. Check service endpoints
kubectl get endpoints <db-service>

# 3. Verify DNS resolution
kubectl exec <app-pod> -- nslookup <db-service>

# 4. Check network policies
kubectl get networkpolicy
```

**Solution:**
```yaml
# Ensure proper service configuration
apiVersion: v1
kind: Service
metadata:
  name: database-service
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
```

### Scenario 3: Persistent Storage Issues
```
Symptoms:
- Data not persisting across pod restarts
- Permission denied on volume mounts
- Pod stuck in ContainerCreating
```

**Investigation Steps:**
```bash
# 1. Check PVC status
kubectl get pvc

# 2. Check PV binding
kubectl describe pvc <pvc-name>

# 3. Check storage class
kubectl get storageclass

# 4. Check pod events
kubectl describe pod <pod-name>
```

**Solution:**
```yaml
# Fix volume permissions
spec:
  securityContext:
    fsGroup: 2000
  containers:
  - name: app
    securityContext:
      runAsUser: 1000
    volumeMounts:
    - name: data
      mountPath: /data
```

## 📚 Reference Materials

### Log Analysis Patterns
```bash
# Common error patterns to search for
kubectl logs <pod-name> | grep -i "error\|exception\|failed\|denied"

# Memory issues
kubectl logs <pod-name> | grep -i "out of memory\|oom\|killed"

# Network issues
kubectl logs <pod-name> | grep -i "connection\|timeout\|refused"

# Permission issues
kubectl logs <pod-name> | grep -i "permission\|denied\|forbidden"
```

### Useful One-Liners
```bash
# Get all pods with issues
kubectl get pods --all-namespaces | grep -v Running

# Check resource usage across all pods
kubectl top pods --all-namespaces --sort-by=memory

# Find pods with most restarts
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'

# Get all events sorted by time
kubectl get events --sort-by=.metadata.creationTimestamp

# Check pod IP and node assignment
kubectl get pods -o wide
```

### Emergency Commands
```bash
# Force delete stuck pod
kubectl delete pod <pod-name> --grace-period=0 --force

# Drain node for maintenance
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Emergency pod for debugging
kubectl run debug --image=busybox --rm -it -- sh

# Quick nginx test pod
kubectl run test-nginx --image=nginx --port=80 --rm -it
```

## 🎓 Best Practices for Prevention

### 1. Proactive Monitoring
- Set up comprehensive logging
- Implement health checks for all containers
- Monitor resource usage trends
- Set up alerting for pod failures

### 2. Configuration Management
- Use ConfigMaps for configuration
- Keep secrets secure and rotated
- Version your configurations
- Test configurations in staging

### 3. Resource Management
- Always set resource requests and limits
- Monitor actual usage vs requests
- Use horizontal pod autoscaling
- Plan for peak loads

### 4. Health Checks
- Implement readiness probes for all services
- Use liveness probes judiciously
- Test health check endpoints regularly
- Set appropriate timeout values

### 5. Documentation
- Document known issues and solutions
- Keep runbooks updated
- Document architecture decisions
- Maintain troubleshooting procedures

## 🔗 Additional Resources

### Official Documentation
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

### Community Resources
- [Kubernetes Slack](https://kubernetes.slack.com)
- [Stack Overflow Kubernetes](https://stackoverflow.com/questions/tagged/kubernetes)
- [Reddit r/kubernetes](https://reddit.com/r/kubernetes)

### Tools
- [kubectl debugging guide](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [kubectx/kubens](https://github.com/ahmetb/kubectx)
- [stern](https://github.com/wercker/stern) - Multi-pod tail
- [k9s](https://github.com/derailed/k9s) - Terminal UI

---

**Remember: Systematic troubleshooting saves time and prevents recurring issues. Document your solutions and share knowledge with your team!**