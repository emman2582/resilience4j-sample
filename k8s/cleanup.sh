#!/bin/bash

# Resilience4j Kubernetes Cleanup Script
# This script removes all deployed resources

echo "🧹 Cleaning up Resilience4j Kubernetes deployment..."

# Stop any port forwarding processes
echo "🔌 Stopping port forwarding processes..."
pkill -f "kubectl port-forward" || true

# Delete namespace and wait for termination
echo "🗑️ Deleting namespace resilience4j-local..."
kubectl delete namespace resilience4j-local --timeout=60s || true

# Force delete stuck resources if namespace still exists
if kubectl get namespace resilience4j-local >/dev/null 2>&1; then
    echo "⚠️ Namespace still exists, force cleaning resources..."
    kubectl delete all --all -n resilience4j-local --force --grace-period=0 || true
    kubectl delete pvc --all -n resilience4j-local --force --grace-period=0 || true
    kubectl delete configmaps --all -n resilience4j-local --force --grace-period=0 || true
    kubectl delete secrets --all -n resilience4j-local --force --grace-period=0 || true
fi

echo "✅ Cleanup completed!"
echo "📊 Remaining namespaces:"
kubectl get namespaces | grep resilience4j || echo "No resilience4j namespaces found"