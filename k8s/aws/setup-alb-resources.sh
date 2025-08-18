#!/bin/bash

# AWS ALB and Target Group Setup Script

TYPE=${1:-single}
REGION=${2:-us-east-1}

case $TYPE in
  "single")
    NAMESPACE="resilience4j-single"
    ;;
  "multi")
    NAMESPACE="resilience4j-multi"
    ;;
  *)
    echo "Usage: $0 [single|multi] [region]"
    exit 1
    ;;
esac

echo "🚀 Setting up AWS ALB resources for $TYPE environment in $REGION..."

# Get cluster info
CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2 2>/dev/null || echo "resilience4j-dev")
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.vpcId' --output text)
SUBNETS=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.subnetIds' --output text)

echo "📋 Cluster: $CLUSTER_NAME"
echo "📋 VPC: $VPC_ID"
echo "📋 Subnets: $SUBNETS"

# Create security group for ALB
echo "🔒 Creating ALB security group..."
ALB_SG_ID=$(aws ec2 create-security-group \
    --group-name "resilience4j-alb-sg-$TYPE" \
    --description "Security group for Resilience4j ALB - $TYPE" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' \
    --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=resilience4j-alb-sg-$TYPE" \
        --region $REGION \
        --query 'SecurityGroups[0].GroupId' \
        --output text)

echo "📋 ALB Security Group: $ALB_SG_ID"

# Add ingress rules to ALB security group
aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "Port 80 rule already exists"

aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG_ID \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "Port 8080 rule already exists"

aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG_ID \
    --protocol tcp \
    --port 3000 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "Port 3000 rule already exists"

# Create ALB
echo "⚖️ Creating Application Load Balancer..."
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name "resilience4j-alb-$TYPE" \
    --subnets $SUBNETS \
    --security-groups $ALB_SG_ID \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4 \
    --region $REGION \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text 2>/dev/null || \
    aws elbv2 describe-load-balancers \
        --names "resilience4j-alb-$TYPE" \
        --region $REGION \
        --query 'LoadBalancers[0].LoadBalancerArn' \
        --output text)

ALB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns $ALB_ARN \
    --region $REGION \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

echo "📋 ALB ARN: $ALB_ARN"
echo "📋 ALB DNS: $ALB_DNS"

# Create target groups
echo "🎯 Creating target groups..."

# Service A target group
SERVICE_A_TG_ARN=$(aws elbv2 create-target-group \
    --name "resilience4j-service-a-$TYPE" \
    --protocol HTTP \
    --port 8080 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-protocol HTTP \
    --health-check-path /actuator/health \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --region $REGION \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text 2>/dev/null || \
    aws elbv2 describe-target-groups \
        --names "resilience4j-service-a-$TYPE" \
        --region $REGION \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text)

# Grafana target group
GRAFANA_TG_ARN=$(aws elbv2 create-target-group \
    --name "resilience4j-grafana-$TYPE" \
    --protocol HTTP \
    --port 3000 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-protocol HTTP \
    --health-check-path /api/health \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --region $REGION \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text 2>/dev/null || \
    aws elbv2 describe-target-groups \
        --names "resilience4j-grafana-$TYPE" \
        --region $REGION \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text)

echo "📋 Service A TG: $SERVICE_A_TG_ARN"
echo "📋 Grafana TG: $GRAFANA_TG_ARN"

# Create ALB listener
echo "👂 Creating ALB listener..."
LISTENER_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=fixed-response,FixedResponseConfig='{StatusCode=404,ContentType=text/plain,MessageBody=Not Found}' \
    --region $REGION \
    --query 'Listeners[0].ListenerArn' \
    --output text 2>/dev/null || \
    aws elbv2 describe-listeners \
        --load-balancer-arn $ALB_ARN \
        --region $REGION \
        --query 'Listeners[0].ListenerArn' \
        --output text)

echo "📋 Listener ARN: $LISTENER_ARN"

# Create listener rules
echo "📏 Creating listener rules..."

# Rule for Grafana (higher priority)
aws elbv2 create-rule \
    --listener-arn $LISTENER_ARN \
    --priority 100 \
    --conditions Field=path-pattern,Values='/grafana*' \
    --actions Type=forward,TargetGroupArn=$GRAFANA_TG_ARN \
    --region $REGION 2>/dev/null || echo "Grafana rule already exists"

# Rule for Service A (lower priority - catch all)
aws elbv2 create-rule \
    --listener-arn $LISTENER_ARN \
    --priority 200 \
    --conditions Field=path-pattern,Values='/*' \
    --actions Type=forward,TargetGroupArn=$SERVICE_A_TG_ARN \
    --region $REGION 2>/dev/null || echo "Service A rule already exists"

# Wait for ALB to be active
echo "⏳ Waiting for ALB to be active..."
aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN --region $REGION

# Output configuration for Kubernetes
echo "✅ AWS ALB resources created successfully!"
echo ""
echo "📋 Configuration Summary:"
echo "ALB DNS: $ALB_DNS"
echo "Service A: http://$ALB_DNS/"
echo "Grafana: http://$ALB_DNS/grafana"
echo ""
echo "🔧 Next steps:"
echo "1. Deploy Kubernetes resources: kubectl apply -f $TYPE/all-in-one.yaml"
echo "2. Register pod IPs with target groups (done automatically by ALB controller)"
echo "3. Test endpoints after 2-3 minutes"

# Save configuration
cat > "alb-config-$TYPE.env" << EOF
ALB_ARN=$ALB_ARN
ALB_DNS=$ALB_DNS
SERVICE_A_TG_ARN=$SERVICE_A_TG_ARN
GRAFANA_TG_ARN=$GRAFANA_TG_ARN
LISTENER_ARN=$LISTENER_ARN
ALB_SG_ID=$ALB_SG_ID
NAMESPACE=$NAMESPACE
EOF

echo "💾 Configuration saved to alb-config-$TYPE.env"