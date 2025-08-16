#!/bin/bash

# AWS Helm Cleanup Script

set -e

CLUSTER_NAME=${1:-resilience4j-cluster}
REGION=${2:-us-east-1}
RELEASE_NAME=${3:-resilience4j-stack}

echo "🧹 Cleaning up AWS Helm deployment..."
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Release: $RELEASE_NAME"

# Stop any port forwarding processes
echo "🔌 Stopping port forwarding processes..."
pkill -f "kubectl port-forward" || true

# Determine which namespace to clean based on existing releases
NAMESPACES=("resilience4j-aws-single" "resilience4j-aws-multi")

for NAMESPACE in "${NAMESPACES[@]}"; do
    if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
        echo "🗑️ Found release $RELEASE_NAME in namespace $NAMESPACE"
        
        # Delete ALB Ingress first
        echo "🌐 Deleting ALB Ingress..."
        kubectl delete ingress --all -n $NAMESPACE --timeout=120s || true
        
        # Uninstall Helm release
        echo "📦 Uninstalling Helm release..."
        helm uninstall $RELEASE_NAME -n $NAMESPACE --timeout=300s || true
        
        # Delete namespace
        echo "🗑️ Deleting namespace..."
        kubectl delete namespace $NAMESPACE --timeout=120s || true
        
        break
    fi
done

# Wait for ALB cleanup
echo "⏳ Waiting for ALB cleanup..."
sleep 60

# Delete AWS Load Balancer Controller if no other ingresses exist
if ! kubectl get ingress --all-namespaces | grep -q alb; then
    echo "🗑️ Removing AWS Load Balancer Controller..."
    helm uninstall aws-load-balancer-controller -n kube-system || true
fi

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

echo "✅ AWS cleanup complete!"