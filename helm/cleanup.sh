#!/bin/bash

# Cleanup Script for Resilience4j Stack
# This script removes the Helm deployment and cleans up resources

set -e

RELEASE_NAME="resilience4j-stack"
NAMESPACE="r4j-monitoring"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

echo "🧹 Starting cleanup of Resilience4j Stack..."

# Stop any port forwards
cleanup_port_forwards() {
    echo "🔌 Stopping port forwards..."
    pkill -f "kubectl port-forward.*resilience4j" || true
    if [ -f /tmp/r4j-port-forwards.pids ]; then
        while read pid; do
            if kill -0 $pid 2>/dev/null; then
                kill $pid
            fi
        done < /tmp/r4j-port-forwards.pids
        rm /tmp/r4j-port-forwards.pids
    fi
    print_status "Port forwards stopped"
}

# Uninstall Helm release
uninstall_helm_release() {
    echo "📦 Uninstalling Helm release..."
    if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
        helm uninstall $RELEASE_NAME -n $NAMESPACE
        print_status "Helm release '$RELEASE_NAME' uninstalled"
    else
        print_warning "Helm release '$RELEASE_NAME' not found"
    fi
}

# Delete namespace
delete_namespace() {
    echo "📁 Deleting namespace..."
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        kubectl delete namespace $NAMESPACE --timeout=60s
        print_status "Namespace '$NAMESPACE' deleted"
    else
        print_warning "Namespace '$NAMESPACE' not found"
    fi
}

# Clean up persistent volumes (if any)
cleanup_persistent_volumes() {
    echo "💾 Checking for persistent volumes..."
    local pvs=$(kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.namespace=="'$NAMESPACE'")].metadata.name}' 2>/dev/null || true)
    if [ -n "$pvs" ]; then
        echo "Found persistent volumes: $pvs"
        for pv in $pvs; do
            kubectl delete pv $pv
            print_status "Persistent volume '$pv' deleted"
        done
    else
        print_status "No persistent volumes to clean up"
    fi
}

# Clean up Docker images (optional)
cleanup_docker_images() {
    read -p "🐳 Do you want to remove Docker images? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing Docker images..."
        docker rmi r4j-sample-service-a:0.1.0 2>/dev/null || print_warning "Service A image not found"
        docker rmi r4j-sample-service-b:0.1.0 2>/dev/null || print_warning "Service B image not found"
        print_status "Docker images cleaned up"
    else
        print_status "Skipping Docker image cleanup"
    fi
}

# Verify cleanup
verify_cleanup() {
    echo "🔍 Verifying cleanup..."
    
    # Check if namespace exists
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace '$NAMESPACE' still exists"
    else
        print_status "Namespace successfully removed"
    fi
    
    # Check if Helm release exists
    if helm list -A | grep -q $RELEASE_NAME; then
        print_warning "Helm release '$RELEASE_NAME' still exists"
    else
        print_status "Helm release successfully removed"
    fi
    
    # Check for any remaining resources
    local remaining=$(kubectl get all -l app.kubernetes.io/instance=$RELEASE_NAME --all-namespaces 2>/dev/null | wc -l)
    if [ $remaining -gt 1 ]; then
        print_warning "Some resources may still exist"
        kubectl get all -l app.kubernetes.io/instance=$RELEASE_NAME --all-namespaces
    else
        print_status "All resources cleaned up"
    fi
}

# Main cleanup function
main() {
    cleanup_port_forwards
    uninstall_helm_release
    cleanup_persistent_volumes
    delete_namespace
    cleanup_docker_images
    verify_cleanup
    
    echo ""
    print_status "Cleanup completed! 🎉"
    echo ""
    echo "📝 What was cleaned up:"
    echo "• Helm release '$RELEASE_NAME'"
    echo "• Namespace '$NAMESPACE'"
    echo "• All Kubernetes resources"
    echo "• Port forwards"
    echo "• Persistent volumes (if any)"
    echo "• Docker images (if selected)"
}

# Confirmation prompt
echo "⚠️  This will completely remove the Resilience4j Stack deployment."
echo "   Release: $RELEASE_NAME"
echo "   Namespace: $NAMESPACE"
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    main
else
    echo "Cleanup cancelled."
    exit 0
fi