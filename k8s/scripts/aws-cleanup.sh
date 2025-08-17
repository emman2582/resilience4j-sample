#!/bin/bash

# AWS EKS Cleanup Script

set -e

CLUSTER_NAME=${1:-resilience4j-cluster}
REGION=${2:-us-east-1}

echo "🧹 Cleaning up AWS EKS deployment..."

# Stop any port forwarding processes
echo "🔌 Stopping port forwarding processes..."
pkill -f "kubectl port-forward" || true

# Delete ALB Ingress first (triggers ALB deletion)
echo "🌐 Deleting ALB Ingress..."
kubectl delete ingress resilience4j-ingress -n resilience4j-aws-single --timeout=120s || true
kubectl delete ingress resilience4j-ingress -n resilience4j-aws-multi --timeout=120s || true

# Delete namespaces and wait for termination
echo "🗑️ Deleting namespaces..."
kubectl delete namespace resilience4j-aws-single --timeout=120s || true
kubectl delete namespace resilience4j-aws-multi --timeout=120s || true

# Wait for ALB to be fully deleted
echo "⏳ Waiting for ALB cleanup..."
sleep 30

# Delete EKS cluster
echo "🗑️ Deleting EKS cluster..."
eksctl delete cluster --name $CLUSTER_NAME --region $REGION --wait

# Clean up ECR repositories (optional)
read -p "Delete ECR repositories? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️ Deleting ECR repositories..."
    aws ecr delete-repository --repository-name r4j-sample-service-a --region $REGION --force || true
    aws ecr delete-repository --repository-name r4j-sample-service-b --region $REGION --force || true
fi

echo "✅ Cleanup complete!"