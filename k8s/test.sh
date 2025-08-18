#!/bin/bash

# Simplified testing script for all environments

ENVIRONMENT=${1:-local}

case $ENVIRONMENT in
  "local")
    NAMESPACE="resilience4j-local"
    BASE_URL="http://localhost:8080"
    echo "🧪 Testing local environment..."
    echo "Ensure port forwarding: kubectl port-forward svc/service-a 8080:8080 -n $NAMESPACE"
    ;;
  "single")
    NAMESPACE="resilience4j-single"
    ALB_URL=$(kubectl get ingress resilience4j-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -n "$ALB_URL" ]; then
      BASE_URL="http://$ALB_URL"
    else
      BASE_URL="http://localhost:8080"
      echo "⚠️ ALB not ready, use port forwarding: kubectl port-forward svc/service-a 8080:8080 -n $NAMESPACE"
    fi
    echo "🧪 Testing single-node environment..."
    ;;
  "multi")
    NAMESPACE="resilience4j-multi"
    ALB_URL=$(kubectl get ingress resilience4j-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -n "$ALB_URL" ]; then
      BASE_URL="http://$ALB_URL"
    else
      BASE_URL="http://localhost:8080"
      echo "⚠️ ALB not ready, use port forwarding: kubectl port-forward svc/service-a 8080:8080 -n $NAMESPACE"
    fi
    echo "🧪 Testing multi-node environment..."
    ;;
  *)
    echo "Usage: $0 [local|single|multi]"
    exit 1
    ;;
esac

echo "Base URL: $BASE_URL"
echo ""

# Test basic connectivity
echo "🔍 Testing basic connectivity..."
curl -s "$BASE_URL/actuator/health" | head -1

# Test resilience patterns
echo ""
echo "⚡ Testing circuit breaker..."
curl -s "$BASE_URL/api/a/flaky?failRate=60" | head -1

echo ""
echo "⏱️ Testing timeout..."
curl -s "$BASE_URL/api/a/slow?delayMs=2500" | head -1

echo ""
echo "🚧 Testing bulkhead..."
curl -s "$BASE_URL/api/a/bulkhead/x" | head -1

echo ""
echo "🚦 Testing rate limiter..."
curl -s "$BASE_URL/api/a/limited" | head -1

echo ""
echo "✅ Testing complete!"