#!/bin/bash

# Comprehensive status check script

echo "📊 Kubernetes Deployment Status Check"
echo "======================================"

echo ""
echo "🏃 Pod Status:"
kubectl get pods -o wide

echo ""
echo "🌐 Service Status:"
kubectl get services

echo ""
echo "📋 ConfigMap Status:"
kubectl get configmaps

echo ""
echo "🔍 Detailed Pod Information:"
for pod in $(kubectl get pods -o jsonpath='{.items[*].metadata.name}'); do
    echo ""
    echo "Pod: $pod"
    echo "Status: $(kubectl get pod $pod -o jsonpath='{.status.phase}')"
    echo "Ready: $(kubectl get pod $pod -o jsonpath='{.status.containerStatuses[0].ready}')"
    
    # Check if pod is not running
    if [ "$(kubectl get pod $pod -o jsonpath='{.status.phase}')" != "Running" ]; then
        echo "⚠️  Issues with $pod:"
        kubectl describe pod $pod | grep -A 10 "Events:"
    fi
done

echo ""
echo "🔧 Quick Fixes:"
echo "  - Check pod logs: kubectl logs <pod-name>"
echo "  - Restart deployment: kubectl rollout restart deployment/<deployment-name>"
echo "  - Delete and recreate: kubectl delete pod <pod-name>"