#!/bin/bash

# E-commerce Platform Cleanup Script
# Safely removes all deployed resources with user confirmation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="ecommerce-platform"

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
}

# Function to check if namespace exists
check_namespace() {
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace $NAMESPACE does not exist"
        print_status "Nothing to clean up"
        exit 0
    fi
}

# Function to show current resources
show_resources() {
    print_status "Current resources in namespace $NAMESPACE:"
    echo
    
    echo "Pods:"
    kubectl get pods -n $NAMESPACE 2>/dev/null || echo "  No pods found"
    echo
    
    echo "Services:"
    kubectl get svc -n $NAMESPACE 2>/dev/null || echo "  No services found"
    echo
    
    echo "Deployments:"
    kubectl get deployments -n $NAMESPACE 2>/dev/null || echo "  No deployments found"
    echo
    
    echo "StatefulSets:"
    kubectl get statefulsets -n $NAMESPACE 2>/dev/null || echo "  No statefulsets found"
    echo
    
    echo "ConfigMaps:"
    kubectl get configmaps -n $NAMESPACE 2>/dev/null || echo "  No configmaps found"
    echo
    
    echo "Secrets:"
    kubectl get secrets -n $NAMESPACE 2>/dev/null || echo "  No secrets found"
    echo
    
    echo "PersistentVolumeClaims:"
    kubectl get pvc -n $NAMESPACE 2>/dev/null || echo "  No PVCs found"
    echo
}

# Function to get user confirmation
get_confirmation() {
    local message=$1
    local default=${2:-"N"}
    
    if [ "$default" = "Y" ]; then
        read -p "$message (Y/n): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Nn]$ ]] && return 1 || return 0
    else
        read -p "$message (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

# Function to cleanup applications only (preserve data)
cleanup_applications() {
    print_status "Cleaning up applications (preserving data)..."
    
    # Delete deployments and services, but keep StatefulSets and PVCs
    kubectl delete deployments --all -n $NAMESPACE 2>/dev/null || true
    kubectl delete services --all -n $NAMESPACE 2>/dev/null || true
    kubectl delete configmaps --all -n $NAMESPACE 2>/dev/null || true
    
    print_success "Applications cleaned up (data preserved)"
}

# Function to cleanup everything including data
cleanup_everything() {
    print_status "Cleaning up everything including data..."
    
    # Delete the entire namespace (this removes everything)
    kubectl delete namespace $NAMESPACE
    
    print_success "Namespace $NAMESPACE and all resources deleted"
    
    # Check for orphaned PVs
    print_status "Checking for orphaned PersistentVolumes..."
    ORPHANED_PVS=$(kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.namespace=="'$NAMESPACE'")].metadata.name}' 2>/dev/null || true)
    
    if [ -n "$ORPHANED_PVS" ]; then
        print_warning "Found orphaned PersistentVolumes:"
        for pv in $ORPHANED_PVS; do
            echo "  - $pv"
        done
        echo
        
        if get_confirmation "Do you want to delete these orphaned PersistentVolumes?"; then
            for pv in $ORPHANED_PVS; do
                kubectl delete pv $pv
                print_status "Deleted PersistentVolume: $pv"
            done
            print_success "Orphaned PersistentVolumes cleaned up"
        else
            print_warning "Orphaned PersistentVolumes left intact"
        fi
    else
        print_status "No orphaned PersistentVolumes found"
    fi
}

# Function to cleanup specific components
cleanup_component() {
    local component=$1
    
    case $component in
        "frontend")
            print_status "Cleaning up frontend components..."
            kubectl delete -f frontend/ 2>/dev/null || true
            print_success "Frontend components cleaned up"
            ;;
        "backend")
            print_status "Cleaning up backend components..."
            kubectl delete -f backend/ 2>/dev/null || true
            print_success "Backend components cleaned up"
            ;;
        "database")
            print_warning "This will delete the database and ALL DATA!"
            if get_confirmation "Are you sure you want to delete the database?"; then
                print_status "Cleaning up database components..."
                kubectl delete -f database/ 2>/dev/null || true
                print_success "Database components cleaned up"
            else
                print_status "Database cleanup cancelled"
            fi
            ;;
        "blue-green")
            print_status "Cleaning up blue-green deployment..."
            kubectl delete -f deployment-strategies/blue-green-setup.yaml 2>/dev/null || true
            print_success "Blue-green deployment cleaned up"
            ;;
        *)
            print_error "Unknown component: $component"
            print_status "Available components: frontend, backend, database, blue-green"
            exit 1
            ;;
    esac
}

# Function to show cleanup options
show_menu() {
    echo "=================================================================="
    echo "   E-commerce Platform Cleanup Options"
    echo "=================================================================="
    echo
    echo "1. Clean up applications only (preserve data)"
    echo "2. Clean up everything including data"
    echo "3. Clean up specific component"
    echo "4. Show current resources"
    echo "5. Cancel"
    echo
}

# Function to handle interactive menu
interactive_cleanup() {
    show_menu
    read -p "Select an option (1-5): " -n 1 -r
    echo
    echo
    
    case $REPLY in
        1)
            print_warning "This will remove applications but preserve database data"
            if get_confirmation "Continue with application cleanup?"; then
                cleanup_applications
            else
                print_status "Cleanup cancelled"
            fi
            ;;
        2)
            print_warning "This will remove EVERYTHING including all data!"
            if get_confirmation "Are you absolutely sure?"; then
                cleanup_everything
            else
                print_status "Cleanup cancelled"
            fi
            ;;
        3)
            echo "Available components:"
            echo "  - frontend"
            echo "  - backend"
            echo "  - database"
            echo "  - blue-green"
            echo
            read -p "Enter component name: " component
            cleanup_component "$component"
            ;;
        4)
            show_resources
            ;;
        5)
            print_status "Cleanup cancelled"
            exit 0
            ;;
        *)
            print_error "Invalid option"
            exit 1
            ;;
    esac
}

# Function to show help
show_help() {
    echo "E-commerce Platform Cleanup Script"
    echo
    echo "Usage: $0 [OPTIONS] [COMPONENT]"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -a, --apps-only         Clean up applications only (preserve data)"
    echo "  -f, --force             Clean up everything without confirmation"
    echo "  -i, --interactive       Interactive cleanup menu (default)"
    echo "  -s, --show              Show current resources only"
    echo
    echo "Components:"
    echo "  frontend                Clean up frontend tier only"
    echo "  backend                 Clean up backend tier only"
    echo "  database                Clean up database tier only (WARNING: deletes data)"
    echo "  blue-green              Clean up blue-green deployment only"
    echo
    echo "Examples:"
    echo "  $0                      Interactive cleanup menu"
    echo "  $0 -a                   Clean up applications only"
    echo "  $0 -f                   Force cleanup of everything"
    echo "  $0 frontend             Clean up frontend tier only"
    echo "  $0 -s                   Show current resources"
}

# Main function
main() {
    # Parse command line arguments
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--apps-only)
            print_warning "Cleaning up applications only (preserving data)"
            if get_confirmation "Continue?"; then
                cleanup_applications
            fi
            ;;
        -f|--force)
            print_warning "Force cleanup of everything including data"
            cleanup_everything
            ;;
        -s|--show)
            show_resources
            ;;
        -i|--interactive|"")
            interactive_cleanup
            ;;
        frontend|backend|database|blue-green)
            cleanup_component "$1"
            ;;
        *)
            print_error "Unknown option: $1"
            print_status "Use -h or --help for usage information"
            exit 1
            ;;
    esac
}

# Handle script interruption
trap 'print_error "Cleanup interrupted by user"; exit 1' INT

# Pre-flight checks
check_kubectl
check_namespace

# Run main function
main "$@"

print_status "Cleanup completed!"