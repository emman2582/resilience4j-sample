#!/bin/bash

# Helm Cleanup Script for all environments

echo "🧹 Cleaning up Helm deployments..."

# Stop any port forwarding processes
echo "🔌 Stopping port forwarding processes..."
pkill -f "kubectl port-forward" || true

# Function to cleanup Helm release and namespace
cleanup_release() {
    local release_name=$1
    local namespace=$2
    
    echo "🗑️ Cleaning up release: $release_name in namespace: $namespace"
    
    # Uninstall Helm release
    helm uninstall $release_name -n $namespace --timeout=120s || true
    
    # Delete namespace
    kubectl delete namespace $namespace --timeout=120s || true
    
    # Force cleanup if namespace still exists
    if kubectl get namespace $namespace >/dev/null 2>&1; then
        echo "⚠️ Force cleaning namespace: $namespace"
        kubectl delete all --all -n $namespace --force --grace-period=0 || true
        kubectl delete pvc --all -n $namespace --force --grace-period=0 || true
        kubectl patch namespace $namespace -p '{"metadata":{"finalizers":[]}}' --type=merge || true
    fi
}

# Cleanup all possible releases
cleanup_release "resilience4j-stack" "resilience4j-local"
cleanup_release "resilience4j-stack" "resilience4j-aws-single" 
cleanup_release "resilience4j-stack" "resilience4j-aws-multi"
cleanup_release "resilience4j-stack" "default"

echo "✅ Helm cleanup completed!"
echo "📊 Remaining namespaces:"
kubectl get namespaces | grep resilience4j || echo "No resilience4j namespaces found"