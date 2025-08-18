#!/bin/bash

# Simplified deployment script for all environments

ENVIRONMENT=${1:-local}

case $ENVIRONMENT in
  "local")
    echo "🏠 Deploying to local minikube..."
    kubectl apply -f local/all-in-one.yaml
    echo "✅ Local deployment complete!"
    echo "📋 Next steps:"
    echo "  kubectl port-forward svc/service-a 8080:8080 -n resilience4j-local"
    echo "  kubectl port-forward svc/grafana 3000:3000 -n resilience4j-local"
    ;;
  "single")
    echo "☁️ Deploying to AWS single-node..."
    # Replace ECR_URI placeholder
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=${2:-us-east-1}
    ECR_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
    
    sed "s|ECR_URI|$ECR_URI|g" single/all-in-one.yaml | kubectl apply -f -
    echo "✅ Single-node deployment complete!"
    echo "📋 Next steps:"
    echo "  kubectl get ingress -n resilience4j-single"
    ;;
  "multi")
    echo "☁️ Deploying to AWS multi-node..."
    # Replace ECR_URI placeholder
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=${2:-us-east-1}
    ECR_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
    
    sed "s|ECR_URI|$ECR_URI|g" multi/all-in-one.yaml | kubectl apply -f -
    echo "✅ Multi-node deployment complete!"
    echo "📋 Next steps:"
    echo "  kubectl get ingress -n resilience4j-multi"
    echo "  kubectl get hpa -n resilience4j-multi"
    ;;
  *)
    echo "Usage: $0 [local|single|multi] [region]"
    echo "Examples:"
    echo "  $0 local"
    echo "  $0 single us-east-1"
    echo "  $0 multi us-west-2"
    exit 1
    ;;
esac