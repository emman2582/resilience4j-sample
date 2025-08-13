#!/bin/bash

# Resilience4j Kubernetes Cleanup Script
# This script removes all deployed resources

echo "🧹 Cleaning up Resilience4j Kubernetes deployment..."

# Delete all resources
kubectl delete -f deployments/
kubectl delete -f services/
kubectl delete -f configs/

echo "✅ Cleanup completed!"
echo ""
echo "📊 Remaining resources (should be empty):"
kubectl get pods,services,configmaps -l app