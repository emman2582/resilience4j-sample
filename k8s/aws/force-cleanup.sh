#!/bin/bash

# Force cleanup script for EKS cluster and resources

REGION=${1:-us-east-1}
CLUSTER_NAME=${2:-resilience4j-dev}

echo "🧹 Force cleaning up EKS cluster and resources..."

# Step 1: Delete all applications and namespaces
echo "🗑️ Deleting application namespaces..."
kubectl delete namespace resilience4j-single --ignore-not-found=true --force --grace-period=0
kubectl delete namespace resilience4j-multi --ignore-not-found=true --force --grace-period=0

# Step 2: Delete all ingresses and services
echo "🗑️ Deleting ingresses and load balancers..."
kubectl delete ingress --all --all-namespaces --force --grace-period=0
kubectl delete service --all --all-namespaces --force --grace-period=0 --field-selector spec.type=LoadBalancer

# Step 3: Delete ALB controller
echo "🗑️ Deleting ALB controller..."
helm uninstall aws-load-balancer-controller -n kube-system --ignore-not-found

# Step 4: Delete all remaining pods forcefully
echo "🗑️ Force deleting remaining pods..."
kubectl delete pods --all --all-namespaces --force --grace-period=0

# Step 5: Delete PodDisruptionBudgets
echo "🗑️ Deleting PodDisruptionBudgets..."
kubectl delete pdb --all --all-namespaces --force --grace-period=0

# Step 6: Clean up ALB resources manually
echo "🗑️ Cleaning up ALB resources..."

# Delete all ALBs with resilience4j in name
ALB_ARNS=$(aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?contains(LoadBalancerName, 'resilience4j')].LoadBalancerArn" --output text)
for alb_arn in $ALB_ARNS; do
    echo "Deleting ALB: $alb_arn"
    aws elbv2 delete-load-balancer --load-balancer-arn $alb_arn --region $REGION
done

# Delete target groups
TG_ARNS=$(aws elbv2 describe-target-groups --region $REGION --query "TargetGroups[?contains(TargetGroupName, 'resilience4j')].TargetGroupArn" --output text)
for tg_arn in $TG_ARNS; do
    echo "Deleting Target Group: $tg_arn"
    aws elbv2 delete-target-group --target-group-arn $tg_arn --region $REGION
done

# Delete security groups
SG_IDS=$(aws ec2 describe-security-groups --region $REGION --query "SecurityGroups[?contains(GroupName, 'resilience4j')].GroupId" --output text)
for sg_id in $SG_IDS; do
    echo "Deleting Security Group: $sg_id"
    aws ec2 delete-security-group --group-id $sg_id --region $REGION 2>/dev/null || echo "Could not delete $sg_id (may be in use)"
done

# Step 7: Wait a moment for resources to be deleted
echo "⏳ Waiting for resources to be cleaned up..."
sleep 30

# Step 8: Force delete cluster with disable-nodegroup-eviction
echo "🗑️ Force deleting EKS cluster..."
eksctl delete cluster $CLUSTER_NAME --region $REGION --disable-nodegroup-eviction --force

# Step 9: Clean up ECR repositories
echo "🗑️ Deleting ECR repositories..."
aws ecr delete-repository --repository-name r4j-sample-service-a --region $REGION --force 2>/dev/null || echo "Service A repository not found"
aws ecr delete-repository --repository-name r4j-sample-service-b --region $REGION --force 2>/dev/null || echo "Service B repository not found"

# Step 10: Clean up IAM roles and policies
echo "🗑️ Cleaning up IAM resources..."
aws iam detach-role-policy --role-name AmazonEKSLoadBalancerControllerRole --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy 2>/dev/null || echo "Policy not attached"
aws iam delete-role --role-name AmazonEKSLoadBalancerControllerRole 2>/dev/null || echo "Role not found"

# Clean up local files
rm -f alb-config-*.env
rm -f ingress-*.yaml
rm -f iam_policy*.json

echo "✅ Force cleanup completed!"
echo ""
echo "💡 If cluster deletion still fails, try:"
echo "1. Check AWS Console for remaining resources"
echo "2. Delete CloudFormation stacks manually"
echo "3. Use: aws eks delete-cluster --name $CLUSTER_NAME --region $REGION"