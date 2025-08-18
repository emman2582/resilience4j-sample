#!/bin/bash

# Status check script for all environments

ENVIRONMENT=${1:-local}

case $ENVIRONMENT in
  "local")
    NAMESPACE="resilience4j-local"
    ;;
  "single")
    NAMESPACE="resilience4j-single"
    ;;
  "multi")
    NAMESPACE="resilience4j-multi"
    ;;
  *)
    echo "Usage: $0 [local|single|multi]"
    exit 1
    ;;
esac

echo "📊 Status for $ENVIRONMENT environment"
echo "Namespace: $NAMESPACE"
echo ""

# Check namespace
if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
  echo "✅ Namespace exists"
else
  echo "❌ Namespace not found"
  exit 1
fi

# Check pods
echo ""
echo "🔍 Pod Status:"
kubectl get pods -n $NAMESPACE

# Check services
echo ""
echo "🔍 Service Status:"
kubectl get services -n $NAMESPACE

# Check ingress (for AWS environments)
if [[ $ENVIRONMENT == "single" || $ENVIRONMENT == "multi" ]]; then
  echo ""
  echo "🔍 Ingress Status:"
  kubectl get ingress -n $NAMESPACE
fi

# Check HPA (for multi environment)
if [[ $ENVIRONMENT == "multi" ]]; then
  echo ""
  echo "🔍 HPA Status:"
  kubectl get hpa -n $NAMESPACE
fi

echo ""
echo "✅ Status check complete!"