#!/bin/bash

# E-commerce Platform Testing Script
# Comprehensive testing suite for the deployed Kubernetes solution

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="ecommerce-platform"
TIMEOUT=30
TEST_RESULTS=()

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

print_test_result() {
    local test_name=$1
    local result=$2
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}[PASS]${NC} $test_name"
        TEST_RESULTS+=("PASS: $test_name")
    else
        echo -e "${RED}[FAIL]${NC} $test_name"
        TEST_RESULTS+=("FAIL: $test_name")
    fi
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
}

# Function to check if namespace exists
check_namespace() {
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_error "Namespace $NAMESPACE does not exist. Please deploy the solution first."
        exit 1
    fi
}

# Test 1: Pod Health Check
test_pod_health() {
    print_status "Testing pod health..."
    
    local failed_pods=0
    local total_pods=0
    
    # Get all pods in the namespace
    while IFS= read -r line; do
        if [ -z "$line" ]; then continue; fi
        
        local pod_name=$(echo $line | awk '{print $1}')
        local status=$(echo $line | awk '{print $3}')
        local ready=$(echo $line | awk '{print $2}')
        
        total_pods=$((total_pods + 1))
        
        if [[ "$status" != "Running" && "$status" != "Completed" ]]; then
            print_error "Pod $pod_name is in $status state"
            failed_pods=$((failed_pods + 1))
        elif [[ "$ready" =~ "0/" ]]; then
            print_error "Pod $pod_name is not ready ($ready)"
            failed_pods=$((failed_pods + 1))
        fi
    done < <(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null)
    
    if [ $failed_pods -eq 0 ]; then
        print_test_result "Pod Health Check" "PASS"
        print_status "All $total_pods pods are healthy"
    else
        print_test_result "Pod Health Check" "FAIL"
        print_error "$failed_pods out of $total_pods pods are unhealthy"
    fi
}

# Test 2: Service Connectivity
test_service_connectivity() {
    print_status "Testing service connectivity..."
    
    local tests_passed=0
    local total_tests=0
    
    # Test frontend service
    total_tests=$((total_tests + 1))
    if kubectl get svc frontend-service -n $NAMESPACE &> /dev/null; then
        print_status "Frontend service exists"
        tests_passed=$((tests_passed + 1))
    else
        print_error "Frontend service not found"
    fi
    
    # Test backend service
    total_tests=$((total_tests + 1))
    if kubectl get svc backend-service -n $NAMESPACE &> /dev/null; then
        print_status "Backend service exists"
        tests_passed=$((tests_passed + 1))
    else
        print_error "Backend service not found"
    fi
    
    # Test database service
    total_tests=$((total_tests + 1))
    if kubectl get svc database-service -n $NAMESPACE &> /dev/null; then
        print_status "Database service exists"
        tests_passed=$((tests_passed + 1))
    else
        print_error "Database service not found"
    fi
    
    if [ $tests_passed -eq $total_tests ]; then
        print_test_result "Service Connectivity" "PASS"
    else
        print_test_result "Service Connectivity" "FAIL"
    fi
}

# Test 3: Frontend to Backend Communication
test_frontend_backend() {
    print_status "Testing frontend to backend communication..."
    
    local frontend_pod=$(kubectl get pods -n $NAMESPACE -l component=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$frontend_pod" ]; then
        print_test_result "Frontend to Backend Communication" "FAIL"
        print_error "No frontend pod found"
        return
    fi
    
    # Test health endpoint
    if kubectl exec -n $NAMESPACE $frontend_pod -c nginx -- curl -s --connect-timeout 5 http://backend-service:8080/health > /dev/null 2>&1; then
        print_test_result "Frontend to Backend Communication" "PASS"
        print_status "Frontend can reach backend health endpoint"
    else
        print_test_result "Frontend to Backend Communication" "FAIL"
        print_error "Frontend cannot reach backend"
    fi
}

# Test 4: Backend to Database Communication
test_backend_database() {
    print_status "Testing backend to database communication..."
    
    local backend_pod=$(kubectl get pods -n $NAMESPACE -l component=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$backend_pod" ]; then
        print_test_result "Backend to Database Communication" "FAIL"
        print_error "No backend pod found"
        return
    fi
    
    # Test database connectivity
    if kubectl exec -n $NAMESPACE $backend_pod -c api-server -- pg_isready -h database-service -p 5432 > /dev/null 2>&1; then
        print_test_result "Backend to Database Communication" "PASS"
        print_status "Backend can reach database"
    else
        print_test_result "Backend to Database Communication" "FAIL"
        print_error "Backend cannot reach database"
    fi
}

# Test 5: Database Functionality
test_database_functionality() {
    print_status "Testing database functionality..."
    
    local db_pod=$(kubectl get pods -n $NAMESPACE -l component=database -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$db_pod" ]; then
        print_test_result "Database Functionality" "FAIL"
        print_error "No database pod found"
        return
    fi
    
    # Test database connection and basic query
    if kubectl exec -n $NAMESPACE $db_pod -c postgres -- psql -U postgres -d ecommerce_db -c "SELECT 1;" > /dev/null 2>&1; then
        print_status "Database connection successful"
        
        # Test table existence
        local table_count=$(kubectl exec -n $NAMESPACE $db_pod -c postgres -- psql -U postgres -d ecommerce_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ')
        
        if [ "$table_count" -ge 4 ]; then
            print_test_result "Database Functionality" "PASS"
            print_status "Database has $table_count tables (expected: 4+)"
        else
            print_test_result "Database Functionality" "FAIL"
            print_error "Database has only $table_count tables (expected: 4+)"
        fi
    else
        print_test_result "Database Functionality" "FAIL"
        print_error "Cannot connect to database"
    fi
}

# Test 6: Persistent Storage
test_persistent_storage() {
    print_status "Testing persistent storage..."
    
    local pvc_count=$(kubectl get pvc -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
    
    if [ $pvc_count -gt 0 ]; then
        print_status "Found $pvc_count PersistentVolumeClaims"
        
        # Check if PVCs are bound
        local bound_pvcs=$(kubectl get pvc -n $NAMESPACE --no-headers 2>/dev/null | grep Bound | wc -l)
        
        if [ $bound_pvcs -eq $pvc_count ]; then
            print_test_result "Persistent Storage" "PASS"
            print_status "All PVCs are bound"
        else
            print_test_result "Persistent Storage" "FAIL"
            print_error "Not all PVCs are bound ($bound_pvcs/$pvc_count)"
        fi
    else
        print_test_result "Persistent Storage" "FAIL"
        print_error "No PersistentVolumeClaims found"
    fi
}

# Test 7: Resource Limits and Requests
test_resource_limits() {
    print_status "Testing resource limits and requests..."
    
    local pods_without_limits=0
    local total_containers=0
    
    # Check each pod for resource limits
    while IFS= read -r pod_name; do
        if [ -z "$pod_name" ]; then continue; fi
        
        local containers=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath='{.spec.containers[*].name}' 2>/dev/null)
        
        for container in $containers; do
            total_containers=$((total_containers + 1))
            
            local has_limits=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath="{.spec.containers[?(@.name=='$container')].resources.limits}" 2>/dev/null)
            local has_requests=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath="{.spec.containers[?(@.name=='$container')].resources.requests}" 2>/dev/null)
            
            if [[ -z "$has_limits" || -z "$has_requests" ]]; then
                pods_without_limits=$((pods_without_limits + 1))
                print_warning "Container $container in pod $pod_name missing resource limits/requests"
            fi
        done
    done < <(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n')
    
    if [ $pods_without_limits -eq 0 ]; then
        print_test_result "Resource Limits and Requests" "PASS"
        print_status "All $total_containers containers have resource limits and requests"
    else
        print_test_result "Resource Limits and Requests" "FAIL"
        print_error "$pods_without_limits out of $total_containers containers missing resource limits/requests"
    fi
}

# Test 8: Health Probes
test_health_probes() {
    print_status "Testing health probes..."
    
    local containers_without_probes=0
    local total_containers=0
    
    # Check each pod for health probes
    while IFS= read -r pod_name; do
        if [ -z "$pod_name" ]; then continue; fi
        
        local containers=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath='{.spec.containers[*].name}' 2>/dev/null)
        
        for container in $containers; do
            total_containers=$((total_containers + 1))
            
            local has_readiness=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath="{.spec.containers[?(@.name=='$container')].readinessProbe}" 2>/dev/null)
            local has_liveness=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath="{.spec.containers[?(@.name=='$container')].livenessProbe}" 2>/dev/null)
            
            # Skip probe check for sidecar containers (they might not need probes)
            if [[ "$container" =~ (sidecar|collector|exporter|backup|circuit-breaker|pooler) ]]; then
                continue
            fi
            
            if [[ -z "$has_readiness" && -z "$has_liveness" ]]; then
                containers_without_probes=$((containers_without_probes + 1))
                print_warning "Container $container in pod $pod_name missing health probes"
            fi
        done
    done < <(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n')
    
    if [ $containers_without_probes -eq 0 ]; then
        print_test_result "Health Probes" "PASS"
        print_status "Main containers have appropriate health probes"
    else
        print_test_result "Health Probes" "FAIL"
        print_error "$containers_without_probes main containers missing health probes"
    fi
}

# Test 9: API Endpoints
test_api_endpoints() {
    print_status "Testing API endpoints..."
    
    local backend_pod=$(kubectl get pods -n $NAMESPACE -l component=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$backend_pod" ]; then
        print_test_result "API Endpoints" "FAIL"
        print_error "No backend pod found"
        return
    fi
    
    local endpoints=("/health" "/api/users" "/api/products" "/api/orders")
    local working_endpoints=0
    
    for endpoint in "${endpoints[@]}"; do
        if kubectl exec -n $NAMESPACE $backend_pod -c api-server -- curl -s --connect-timeout 5 http://localhost:8080$endpoint > /dev/null 2>&1; then
            working_endpoints=$((working_endpoints + 1))
            print_status "API endpoint $endpoint is working"
        else
            print_error "API endpoint $endpoint is not responding"
        fi
    done
    
    if [ $working_endpoints -eq ${#endpoints[@]} ]; then
        print_test_result "API Endpoints" "PASS"
    else
        print_test_result "API Endpoints" "FAIL"
        print_error "$working_endpoints out of ${#endpoints[@]} endpoints are working"
    fi
}

# Test 10: Security Context
test_security_context() {
    print_status "Testing security contexts..."
    
    local insecure_pods=0
    local total_pods=0
    
    # Check each pod for security context
    while IFS= read -r pod_name; do
        if [ -z "$pod_name" ]; then continue; fi
        total_pods=$((total_pods + 1))
        
        # Check if pod runs as non-root
        local runs_as_root=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath='{.spec.securityContext.runAsNonRoot}' 2>/dev/null)
        local run_as_user=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath='{.spec.securityContext.runAsUser}' 2>/dev/null)
        
        # Check container security contexts
        local containers=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath='{.spec.containers[*].name}' 2>/dev/null)
        local container_secure=true
        
        for container in $containers; do
            local container_runs_as_root=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath="{.spec.containers[?(@.name=='$container')].securityContext.runAsNonRoot}" 2>/dev/null)
            local allow_privilege_escalation=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath="{.spec.containers[?(@.name=='$container')].securityContext.allowPrivilegeEscalation}" 2>/dev/null)
            
            # Init containers might need to run as root for setup tasks
            if [[ "$container" =~ init ]]; then
                continue
            fi
            
            if [[ "$container_runs_as_root" != "true" && "$runs_as_root" != "true" && "$run_as_user" == "0" ]]; then
                container_secure=false
                break
            fi
        done
        
        if [ "$container_secure" = false ]; then
            insecure_pods=$((insecure_pods + 1))
            print_warning "Pod $pod_name may have security context issues"
        fi
    done < <(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n')
    
    if [ $insecure_pods -eq 0 ]; then
        print_test_result "Security Context" "PASS"
        print_status "All pods have appropriate security contexts"
    else
        print_test_result "Security Context" "FAIL"
        print_error "$insecure_pods out of $total_pods pods have security context issues"
    fi
}

# Function to run load test
run_load_test() {
    print_status "Running basic load test..."
    
    # Get service endpoint
    local service_endpoint="frontend-service.$NAMESPACE.svc.cluster.local"
    
    # Create a temporary load test pod
    kubectl run load-test-pod --image=alpine/curl --rm -i --restart=Never --timeout=60s -- \
        sh -c "
        echo 'Running load test with 50 requests...'
        for i in \$(seq 1 50); do
            curl -s --connect-timeout 2 http://$service_endpoint > /dev/null
            if [ \$? -eq 0 ]; then
                echo -n '.'
            else
                echo -n 'F'
            fi
        done
        echo
        echo 'Load test completed'
        " 2>/dev/null || print_warning "Load test pod failed to complete"
}

# Function to show test summary
show_test_summary() {
    echo
    echo "=================================================================="
    echo "                      TEST SUMMARY"
    echo "=================================================================="
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    for result in "${TEST_RESULTS[@]}"; do
        total_tests=$((total_tests + 1))
        echo "  $result"
        
        if [[ $result == PASS* ]]; then
            passed_tests=$((passed_tests + 1))
        else
            failed_tests=$((failed_tests + 1))
        fi
    done
    
    echo
    echo "Total Tests: $total_tests"
    echo -e "Passed: ${GREEN}$passed_tests${NC}"
    echo -e "Failed: ${RED}$failed_tests${NC}"
    
    if [ $failed_tests -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed! 🎉${NC}"
        echo "Your e-commerce platform is working correctly."
    else
        echo -e "\n${YELLOW}Some tests failed. Please check the issues above.${NC}"
        echo "Use 'kubectl get pods -n $NAMESPACE' to investigate further."
    fi
    
    echo
    echo "Additional commands for troubleshooting:"
    echo "  kubectl logs -f deployment/frontend-deployment -n $NAMESPACE"
    echo "  kubectl logs -f deployment/backend-deployment -n $NAMESPACE"
    echo "  kubectl logs -f statefulset/database -n $NAMESPACE"
    echo "  kubectl describe pod <pod-name> -n $NAMESPACE"
}

# Main function
main() {
    echo "=================================================================="
    echo "   E-commerce Platform Testing Suite"
    echo "=================================================================="
    echo
    
    # Pre-flight checks
    check_kubectl
    check_namespace
    
    print_status "Starting comprehensive testing..."
    echo
    
    # Run all tests
    test_pod_health
    test_service_connectivity
    test_frontend_backend
    test_backend_database
    test_database_functionality
    test_persistent_storage
    test_resource_limits
    test_health_probes
    test_api_endpoints
    test_security_context
    
    # Optional load test
    if [[ "${1:-}" == "--load-test" ]]; then
        run_load_test
    fi
    
    # Show summary
    show_test_summary
}

# Run main function
main "$@"