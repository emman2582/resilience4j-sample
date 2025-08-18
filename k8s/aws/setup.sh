#!/bin/bash

# AWS EKS setup script

TYPE=${1:-single}
REGION=${2:-us-east-1}

case $TYPE in
  "single")
    CLUSTER_FILE="single-cluster.yaml"
    CLUSTER_NAME="resilience4j-dev"
    ;;
  "multi")
    CLUSTER_FILE="multi-cluster.yaml"
    CLUSTER_NAME="resilience4j-prod"
    ;;
  *)
    echo "Usage: $0 [single|multi] [region]"
    exit 1
    ;;
esac

echo "🚀 Setting up $TYPE EKS cluster in $REGION..."

# Update region in cluster config
sed "s/region: us-east-1/region: $REGION/g" $CLUSTER_FILE > temp-cluster.yaml

# Create cluster
eksctl create cluster -f temp-cluster.yaml

# Setup ECR and build images
echo "🐳 Setting up ECR..."
aws ecr create-repository --repository-name r4j-sample-service-a --region $REGION || true
aws ecr create-repository --repository-name r4j-sample-service-b --region $REGION || true

# Build and push images
echo "🔨 Building and pushing images..."
cd ../..
./gradlew clean build

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI

docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/

docker tag r4j-sample-service-a:0.1.0 $ECR_URI/r4j-sample-service-a:0.1.0
docker tag r4j-sample-service-b:0.1.0 $ECR_URI/r4j-sample-service-b:0.1.0

docker push $ECR_URI/r4j-sample-service-a:0.1.0
docker push $ECR_URI/r4j-sample-service-b:0.1.0

# Enable OIDC provider
echo "🔧 Enabling OIDC provider..."
eksctl utils associate-iam-oidc-provider --region=$REGION --cluster=$CLUSTER_NAME --approve

# Install ALB controller for ingress
echo "🔧 Installing ALB controller..."
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json || true

eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region=$REGION

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Cleanup
rm -f temp-cluster.yaml iam_policy.json

echo "✅ AWS setup complete!"
echo "📋 Next steps:"
echo "  cd ../.. && ./deploy.sh $TYPE $REGION"