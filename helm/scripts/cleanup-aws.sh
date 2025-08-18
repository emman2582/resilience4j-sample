#!/bin/bash

# AWS Helm + EKS Cleanup Script for Resilience4j
# Usage: ./cleanup-aws.sh <cluster-name> <region> [release-name]

CLUSTER_NAME=${1:-resilience4j-cluster}
REGION=${2:-us-east-1}
RELEASE_NAME=${3:-resilience4j-stack}

echo "🧹 AWS Helm + EKS Cleanup for Resilience4j"
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Release: $RELEASE_NAME"

# Stop port forwarding processes
echo "🔌 Stopping port forwarding processes..."
if command -v pkill >/dev/null 2>&1; then
    pkill -f "kubectl port-forward" || true
else
    taskkill /F /IM kubectl.exe >nul 2>&1 || true
fi

# Set kubectl context to the cluster
echo "🔧 Setting kubectl context..."
kubectl config use-context "arn:aws:eks:$REGION:$(aws sts get-caller-identity --query Account --output text):cluster/$CLUSTER_NAME" || true

# Clean up Helm releases
echo "🗑️ Cleaning up Helm releases..."
RELEASES=$(helm list --all-namespaces | grep resilience4j | awk '{print $1 ":" $2}')

if [ -n "$RELEASES" ]; then
    echo "Found Helm releases:"
    echo "$RELEASES"
    
    for release_info in $RELEASES; do
        rel_name=$(echo $release_info | cut -d':' -f1)
        rel_namespace=$(echo $release_info | cut -d':' -f2)
        echo "Uninstalling release: $rel_name in namespace: $rel_namespace"
        helm uninstall $rel_name -n $rel_namespace || true
    done
else
    echo "No resilience4j Helm releases found"
fi

# Clean up namespaces
echo "🗑️ Cleaning resilience4j namespaces..."
for ns in resilience4j-local resilience4j-aws-single resilience4j-aws-multi; do
    if kubectl get namespace $ns >/dev/null 2>&1; then
        echo "Deleting namespace: $ns"
        kubectl delete namespace $ns --timeout=60s || true
    fi
done

# Wait for cleanup
echo "⏳ Waiting for cleanup to complete..."
sleep 15

# Force cleanup any stuck resources
echo "🔨 Force cleaning any stuck resources..."
for ns in resilience4j-local resilience4j-aws-single resilience4j-aws-multi; do
    if kubectl get namespace $ns >/dev/null 2>&1; then
        echo "Force cleaning namespace: $ns"
        kubectl delete all --all -n $ns --force --grace-period=0 || true
        kubectl delete pvc --all -n $ns --force --grace-period=0 || true
        kubectl delete configmaps --all -n $ns --force --grace-period=0 || true
        kubectl delete secrets --all -n $ns --force --grace-period=0 || true
        kubectl delete hpa --all -n $ns --force --grace-period=0 || true
        kubectl delete vpa --all -n $ns --force --grace-period=0 || true
    fi
done

# Clean up persistent volumes
echo "💾 Cleaning up persistent volumes..."
PVS=$(kubectl get pv | grep resilience4j | awk '{print $1}')
if [ -n "$PVS" ]; then
    for pv in $PVS; do
        echo "Deleting PV: $pv"
        kubectl delete pv $pv || true
    done
fi

# Delete EKS cluster
echo "☁️ EKS Cluster Cleanup"
read -p "Delete EKS cluster $CLUSTER_NAME? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting EKS cluster: $CLUSTER_NAME"
    eksctl delete cluster --name $CLUSTER_NAME --region $REGION
    echo "✅ EKS cluster deleted"
else
    echo "⏭️ Skipping EKS cluster deletion"
fi

# Clean up ECR repositories
echo "🐳 ECR Repository Cleanup"
read -p "Delete ECR repositories? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    aws ecr delete-repository --repository-name r4j-sample-service-a --region $REGION --force 2>/dev/null || true
    aws ecr delete-repository --repository-name r4j-sample-service-b --region $REGION --force 2>/dev/null || true
    echo "✅ ECR repositories cleaned"
else
    echo "⏭️ Skipping ECR cleanup"
fi

echo "✅ AWS Helm + EKS cleanup completed!"