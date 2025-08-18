#!/bin/bash

# ALB Resources Cleanup Script

TYPE=${1:-single}
REGION=${2:-us-east-1}

case $TYPE in
  "single")
    NAMESPACE="resilience4j-single"
    ALB_NAME="resilience4j-alb-single"
    ;;
  "multi")
    NAMESPACE="resilience4j-multi"
    ALB_NAME="resilience4j-alb-multi"
    ;;
  *)
    echo "Usage: $0 [single|multi] [region]"
    exit 1
    ;;
esac

echo "🧹 Cleaning up ALB resources for $TYPE environment..."

# Load configuration if exists
if [ -f "alb-config-$TYPE.env" ]; then
    source "alb-config-$TYPE.env"
    echo "📋 Loaded configuration from alb-config-$TYPE.env"
else
    echo "⚠️  Configuration file not found, attempting to discover resources..."
    ALB_ARN=$(aws elbv2 describe-load-balancers --names $ALB_NAME --region $REGION --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
fi

# Delete Kubernetes resources first
echo "🗑️  Deleting Kubernetes resources..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true

# Delete ingress files
rm -f "ingress-$TYPE.yaml"

# Delete ALB listener rules (except default)
if [ -n "$LISTENER_ARN" ]; then
    echo "🗑️  Deleting listener rules..."
    RULES=$(aws elbv2 describe-rules --listener-arn $LISTENER_ARN --region $REGION --query 'Rules[?!IsDefault].RuleArn' --output text)
    for rule in $RULES; do
        aws elbv2 delete-rule --rule-arn $rule --region $REGION
        echo "✅ Deleted rule: $rule"
    done
fi

# Delete ALB listener
if [ -n "$LISTENER_ARN" ]; then
    echo "🗑️  Deleting ALB listener..."
    aws elbv2 delete-listener --listener-arn $LISTENER_ARN --region $REGION
    echo "✅ Deleted listener: $LISTENER_ARN"
fi

# Delete target groups
if [ -n "$SERVICE_A_TG_ARN" ]; then
    echo "🗑️  Deleting Service A target group..."
    aws elbv2 delete-target-group --target-group-arn $SERVICE_A_TG_ARN --region $REGION
    echo "✅ Deleted target group: $SERVICE_A_TG_ARN"
fi

if [ -n "$GRAFANA_TG_ARN" ]; then
    echo "🗑️  Deleting Grafana target group..."
    aws elbv2 delete-target-group --target-group-arn $GRAFANA_TG_ARN --region $REGION
    echo "✅ Deleted target group: $GRAFANA_TG_ARN"
fi

# Delete ALB
if [ -n "$ALB_ARN" ]; then
    echo "🗑️  Deleting Application Load Balancer..."
    aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN --region $REGION
    echo "✅ Deleted ALB: $ALB_ARN"
    
    # Wait for ALB to be deleted
    echo "⏳ Waiting for ALB to be deleted..."
    aws elbv2 wait load-balancer-not-exists --load-balancer-arns $ALB_ARN --region $REGION
fi

# Delete security group
if [ -n "$ALB_SG_ID" ]; then
    echo "🗑️  Deleting ALB security group..."
    aws ec2 delete-security-group --group-id $ALB_SG_ID --region $REGION
    echo "✅ Deleted security group: $ALB_SG_ID"
fi

# Clean up configuration files
rm -f "alb-config-$TYPE.env"

echo "✅ Cleanup completed successfully!"
echo ""
echo "💡 To clean up the entire EKS cluster:"
echo "eksctl delete cluster resilience4j-dev --region $REGION"