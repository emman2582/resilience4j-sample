#!/bin/bash

# Quick fix script for current deployment issues

echo "🔧 Fixing current deployment issues..."

# Clean up existing deployment
echo "🧹 Cleaning up existing resources..."
kubectl delete -f deployments/ --ignore-not-found=true
kubectl delete -f services/ --ignore-not-found=true
kubectl delete -f configs/ --ignore-not-found=true

# Wait for cleanup
echo "⏳ Waiting for cleanup..."
sleep 10

# Load images if using minikube
if command -v minikube &> /dev/null && minikube status | grep -q "Running"; then
    echo "🐳 Loading Docker images into minikube..."
    minikube image load r4j-sample-service-a:0.1.0 2>/dev/null || echo "⚠️  Image r4j-sample-service-a:0.1.0 not found locally"
    minikube image load r4j-sample-service-b:0.1.0 2>/dev/null || echo "⚠️  Image r4j-sample-service-b:0.1.0 not found locally"
fi

# Redeploy with fixes
echo "🚀 Redeploying with fixes..."
kubectl apply -f configs/
kubectl apply -f services/
kubectl apply -f deployments/

echo "✅ Deployment fixed! Checking status..."
sleep 5
kubectl get pods