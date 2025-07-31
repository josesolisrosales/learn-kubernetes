#!/bin/bash

# E-commerce Platform Deployment Script
# Deploys the complete Kubernetes solution with error handling and validation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="ecommerce-platform"
TIMEOUT=300  # 5 minutes timeout for deployments

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    print_success "kubectl is available"
}

# Function to check cluster connectivity
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
}

# Function to check if namespace exists
check_namespace() {
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace $NAMESPACE already exists"
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Deployment cancelled"
            exit 1
        fi
    fi
}

# Function to check required StorageClass
check_storage_class() {
    if ! kubectl get storageclass fast-ssd &> /dev/null; then
        print_warning "StorageClass 'fast-ssd' not found"
        print_status "Available StorageClasses:"
        kubectl get storageclass
        
        # Use default storage class if available
        DEFAULT_SC=$(kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')
        if [ -n "$DEFAULT_SC" ]; then
            print_status "Using default StorageClass: $DEFAULT_SC"
            # Update the StatefulSet to use the default storage class
            if [ -f "database/statefulset.yaml" ]; then
                sed -i.bak "s/storageClassName: fast-ssd/storageClassName: $DEFAULT_SC/" database/statefulset.yaml
                print_status "Updated StatefulSet to use StorageClass: $DEFAULT_SC"
            fi
        else
            print_error "No default StorageClass found. Please create 'fast-ssd' StorageClass or update the configuration"
            exit 1
        fi
    else
        print_success "StorageClass 'fast-ssd' is available"
    fi
}

# Function to deploy a component
deploy_component() {
    local component=$1
    local description=$2
    
    print_status "Deploying $description..."
    
    if [ -d "$component" ]; then
        kubectl apply -f "$component/"
        if [ $? -eq 0 ]; then
            print_success "$description deployed successfully"
        else
            print_error "Failed to deploy $description"
            exit 1
        fi
    elif [ -f "$component" ]; then
        kubectl apply -f "$component"
        if [ $? -eq 0 ]; then
            print_success "$description deployed successfully"
        else
            print_error "Failed to deploy $description"
            exit 1
        fi
    else
        print_error "$component not found"
        exit 1
    fi
}

# Function to wait for deployment rollout
wait_for_deployment() {
    local deployment=$1
    local namespace=$2
    
    print_status "Waiting for deployment $deployment to be ready..."
    
    if kubectl rollout status deployment/$deployment -n $namespace --timeout=${TIMEOUT}s; then
        print_success "Deployment $deployment is ready"
    else
        print_error "Deployment $deployment failed to become ready within ${TIMEOUT} seconds"
        kubectl get pods -n $namespace -l app=$deployment
        exit 1
    fi
}

# Function to wait for StatefulSet rollout
wait_for_statefulset() {
    local statefulset=$1
    local namespace=$2
    
    print_status "Waiting for StatefulSet $statefulset to be ready..."
    
    if kubectl rollout status statefulset/$statefulset -n $namespace --timeout=${TIMEOUT}s; then
        print_success "StatefulSet $statefulset is ready"
    else
        print_error "StatefulSet $statefulset failed to become ready within ${TIMEOUT} seconds"
        kubectl get pods -n $namespace -l app=$statefulset
        exit 1
    fi
}

# Function to check pod health
check_pod_health() {
    print_status "Checking pod health..."
    
    # Wait a bit for pods to stabilize
    sleep 10
    
    # Check if all pods are running
    NOT_READY=$(kubectl get pods -n $NAMESPACE --no-headers | grep -v Running | grep -v Completed | wc -l)
    
    if [ $NOT_READY -eq 0 ]; then
        print_success "All pods are running and healthy"
    else
        print_warning "$NOT_READY pods are not ready"
        kubectl get pods -n $NAMESPACE
        
        # Show pod details for troubleshooting
        print_status "Pod details for troubleshooting:"
        kubectl get pods -n $NAMESPACE -o wide
    fi
}

# Function to test connectivity
test_connectivity() {
    print_status "Testing component connectivity..."
    
    # Test frontend to backend connectivity
    FRONTEND_POD=$(kubectl get pods -n $NAMESPACE -l component=frontend -o jsonpath='{.items[0].metadata.name}')
    if [ -n "$FRONTEND_POD" ]; then
        print_status "Testing frontend to backend connectivity..."
        if kubectl exec -n $NAMESPACE $FRONTEND_POD -- curl -s --connect-timeout 5 http://backend-service:8080/health > /dev/null; then
            print_success "Frontend can reach backend"
        else
            print_warning "Frontend cannot reach backend"
        fi
    fi
    
    # Test backend to database connectivity
    BACKEND_POD=$(kubectl get pods -n $NAMESPACE -l component=backend -o jsonpath='{.items[0].metadata.name}')
    if [ -n "$BACKEND_POD" ]; then
        print_status "Testing backend to database connectivity..."
        if kubectl exec -n $NAMESPACE $BACKEND_POD -- pg_isready -h database-service -p 5432 > /dev/null 2>&1; then
            print_success "Backend can reach database"
        else
            print_warning "Backend cannot reach database"
        fi
    fi
}

# Function to show access information
show_access_info() {
    print_status "Deployment completed! Here's how to access your application:"
    echo
    
    # Get LoadBalancer service info
    LB_IP=$(kubectl get svc frontend-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    LB_HOSTNAME=$(kubectl get svc frontend-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    
    if [ -n "$LB_IP" ]; then
        print_success "LoadBalancer IP: http://$LB_IP"
    elif [ -n "$LB_HOSTNAME" ]; then
        print_success "LoadBalancer Hostname: http://$LB_HOSTNAME"
    else
        print_status "LoadBalancer is pending. You can use port-forward instead:"
        echo "  kubectl port-forward svc/frontend-service 8080:80 -n $NAMESPACE"
        echo "  Then access: http://localhost:8080"
    fi
    
    # Show NodePort access
    NODEPORT=$(kubectl get svc frontend-nodeport -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    if [ -n "$NODEPORT" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
        if [ -z "$NODE_IP" ]; then
            NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
        fi
        print_status "NodePort access: http://$NODE_IP:$NODEPORT"
    fi
    
    echo
    print_status "Useful commands:"
    echo "  # Check pod status:"
    echo "    kubectl get pods -n $NAMESPACE"
    echo
    echo "  # Check services:"
    echo "    kubectl get svc -n $NAMESPACE"
    echo
    echo "  # View logs:"
    echo "    kubectl logs -f deployment/frontend-deployment -n $NAMESPACE"
    echo "    kubectl logs -f deployment/backend-deployment -n $NAMESPACE"
    echo "    kubectl logs -f statefulset/database -n $NAMESPACE"
    echo
    echo "  # Access database directly:"
    echo "    kubectl exec -it database-0 -n $NAMESPACE -- psql -U postgres -d ecommerce_db"
    echo
    echo "  # Clean up:"
    echo "    ./cleanup.sh"
}

# Main deployment function
main() {
    echo "=================================================================="
    echo "   E-commerce Platform Kubernetes Deployment Script"
    echo "=================================================================="
    echo
    
    # Pre-flight checks
    print_status "Running pre-flight checks..."
    check_kubectl
    check_cluster
    check_namespace
    check_storage_class
    
    echo
    print_status "Starting deployment..."
    
    # Deploy components in correct order
    deploy_component "namespace.yaml" "Namespace and RBAC"
    sleep 2
    
    deploy_component "database" "Database tier (PostgreSQL)"
    wait_for_statefulset "database" "$NAMESPACE"
    sleep 5  # Give database time to initialize
    
    deploy_component "backend" "Backend tier (API)"
    wait_for_deployment "backend-deployment" "$NAMESPACE"
    sleep 3
    
    deploy_component "frontend" "Frontend tier (Web)"
    wait_for_deployment "frontend-deployment" "$NAMESPACE"
    
    # Health checks
    check_pod_health
    test_connectivity
    
    # Show access information
    echo
    show_access_info
    
    print_success "Deployment completed successfully!"
}

# Handle script interruption
trap 'print_error "Deployment interrupted by user"; exit 1' INT

# Check if running from correct directory
if [ ! -f "namespace.yaml" ]; then
    print_error "Please run this script from the solution directory containing namespace.yaml"
    print_status "Expected directory structure:"
    echo "  solution/"
    echo "    ├── deploy.sh"
    echo "    ├── namespace.yaml"
    echo "    ├── frontend/"
    echo "    ├── backend/"
    echo "    └── database/"
    exit 1
fi

# Run main function
main "$@"