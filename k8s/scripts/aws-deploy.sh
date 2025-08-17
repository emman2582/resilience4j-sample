#!/bin/bash

# AWS EKS Deployment Script for Resilience4j Sample

set -e

CLUSTER_NAME=${1:-resilience4j-cluster}
NODE_COUNT=${2:-1}
REGION=${3:-us-east-1}

echo "🚀 Deploying to AWS EKS..."
echo "Cluster: $CLUSTER_NAME"
echo "Nodes: $NODE_COUNT"
echo "Region: $REGION"

# Create EKS cluster
echo "📦 Creating EKS cluster..."
if [ "$NODE_COUNT" -eq 1 ]; then
    eksctl create cluster \
        --name $CLUSTER_NAME \
        --region $REGION \
        --nodes $NODE_COUNT \
        --node-type t3.medium \
        --managed
else
    eksctl create cluster \
        --name $CLUSTER_NAME \
        --region $REGION \
        --nodes $NODE_COUNT \
        --node-type t3.medium \
        --managed \
        --zones ${REGION}a,${REGION}b
fi

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Build and push images to ECR
echo "🐳 Setting up ECR repositories..."
aws ecr create-repository --repository-name r4j-sample-service-a --region $REGION || true
aws ecr create-repository --repository-name r4j-sample-service-b --region $REGION || true

# Get ECR login
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com

# Build and push images
echo "🔨 Building and pushing images..."
cd ../..
./gradlew clean build

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/

docker tag r4j-sample-service-a:0.1.0 $ECR_URI/r4j-sample-service-a:0.1.0
docker tag r4j-sample-service-b:0.1.0 $ECR_URI/r4j-sample-service-b:0.1.0

docker push $ECR_URI/r4j-sample-service-a:0.1.0
docker push $ECR_URI/r4j-sample-service-b:0.1.0

# Deploy with AWS-specific configuration
cd ../k8s/scripts
echo "🚀 Deploying services to EKS..."

# Determine namespace based on node count
if [ "$NODE_COUNT" -eq 1 ]; then
    NAMESPACE="resilience4j-aws-single"
    DEPLOYMENT_TYPE="single-node"
    kubectl apply -f ../environments/namespace-aws-single.yaml
else
    NAMESPACE="resilience4j-aws-multi"
    DEPLOYMENT_TYPE="multi-node"
    kubectl apply -f ../environments/namespace-aws-multi.yaml
fi

echo "📦 Using namespace: $NAMESPACE"

# Create AWS-specific deployments with proper labels
for file in ../manifests/deployments/*.yaml; do
    filename=$(basename "$file")
    sed "s|r4j-sample-service-a:0.1.0|$ECR_URI/r4j-sample-service-a:0.1.0|g; \
         s|r4j-sample-service-b:0.1.0|$ECR_URI/r4j-sample-service-b:0.1.0|g; \
         s|imagePullPolicy: Never|imagePullPolicy: Always|g; \
         s|namespace: default|namespace: $NAMESPACE|g" "$file" > "../manifests/deployments/${filename%.yaml}-aws.yaml"
    
    # Add environment labels
    sed -i "s|labels:|labels:\n    environment: aws\n    deployment-type: $DEPLOYMENT_TYPE\n    node-count: \"$NODE_COUNT\"|g" "../manifests/deployments/${filename%.yaml}-aws.yaml"
done

# Apply configurations with namespace
kubectl apply -f ../manifests/configs/ -n $NAMESPACE
kubectl apply -f ../manifests/deployments/*-aws.yaml -n $NAMESPACE
kubectl apply -f ../manifests/services/ -n $NAMESPACE

# Create ALB Ingress with proper labels
echo "🌐 Creating ALB Ingress..."
cat > ingress-aws.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: resilience4j-ingress
  namespace: $NAMESPACE
  labels:
    environment: aws
    deployment-type: $DEPLOYMENT_TYPE
    node-count: "$NODE_COUNT"
    app.kubernetes.io/name: resilience4j
    app.kubernetes.io/component: ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: service-a
            port:
              number: 8080
EOF

kubectl apply -f ingress-aws.yaml

echo "✅ Deployment complete!"
echo "📊 Getting ALB URL..."
sleep 30
ALB_URL=$(kubectl get ingress resilience4j-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "🌐 Service A URL: http://$ALB_URL"
echo "📈 Update NodeJS client .env: SERVICE_A_URL=http://$ALB_URL"