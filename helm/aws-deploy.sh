#!/bin/bash

# AWS EKS Helm Deployment Script

set -e

CLUSTER_NAME=${1:-resilience4j-cluster}
NODE_COUNT=${2:-1}
REGION=${3:-us-east-1}
RELEASE_NAME=${4:-resilience4j-stack}

echo "🚀 Deploying Resilience4j Stack to AWS EKS with Helm..."
echo "Cluster: $CLUSTER_NAME"
echo "Nodes: $NODE_COUNT"
echo "Region: $REGION"
echo "Release: $RELEASE_NAME"

# Create EKS cluster if it doesn't exist
if ! eksctl get cluster --name $CLUSTER_NAME --region $REGION >/dev/null 2>&1; then
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
fi

# Setup ECR and build images
echo "🐳 Setting up ECR and building images..."
aws ecr create-repository --repository-name r4j-sample-service-a --region $REGION || true
aws ecr create-repository --repository-name r4j-sample-service-b --region $REGION || true

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com

cd ..
gradle clean build

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/

docker tag r4j-sample-service-a:0.1.0 $ECR_URI/r4j-sample-service-a:0.1.0
docker tag r4j-sample-service-b:0.1.0 $ECR_URI/r4j-sample-service-b:0.1.0

docker push $ECR_URI/r4j-sample-service-a:0.1.0
docker push $ECR_URI/r4j-sample-service-b:0.1.0

# Install AWS Load Balancer Controller
echo "🌐 Installing AWS Load Balancer Controller..."
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master" || true

helm repo add eks https://aws.github.io/eks-charts || true
helm repo update

# Create service account for ALB controller
eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --role-name AmazonEKSLoadBalancerControllerRole \
    --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
    --approve \
    --region=$REGION || true

helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller || true

# Deploy application with appropriate values file
cd helm
echo "🚀 Deploying application..."

if [ "$NODE_COUNT" -eq 1 ]; then
    VALUES_FILE="resilience4j-stack/values-aws-single.yaml"
    NAMESPACE="resilience4j-aws-single"
else
    VALUES_FILE="resilience4j-stack/values-aws-multi.yaml"
    NAMESPACE="resilience4j-aws-multi"
fi

# Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Update image repositories in values file
sed -i.bak "s|repository: r4j-sample-service-a|repository: $ECR_URI/r4j-sample-service-a|g" $VALUES_FILE
sed -i.bak "s|repository: r4j-sample-service-b|repository: $ECR_URI/r4j-sample-service-b|g" $VALUES_FILE

helm upgrade --install $RELEASE_NAME ./resilience4j-stack \
    -f $VALUES_FILE \
    --namespace $NAMESPACE \
    --wait \
    --timeout=10m

# Restore original values file
mv $VALUES_FILE.bak $VALUES_FILE

echo "✅ Deployment complete!"
echo "⏳ Waiting for ALB to be ready..."
sleep 60

ALB_URL=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
if [ -n "$ALB_URL" ]; then
    echo "🌐 Service A URL: http://$ALB_URL"
    echo "📈 Update NodeJS client .env: SERVICE_A_URL=http://$ALB_URL"
else
    echo "⚠️  ALB URL not ready yet. Check with: kubectl get ingress"
fi

echo "📊 Access monitoring:"
echo "   Grafana: kubectl port-forward svc/grafana 3000:3000 -n $NAMESPACE"
echo "   Prometheus: kubectl port-forward svc/prometheus 9090:9090 -n $NAMESPACE"