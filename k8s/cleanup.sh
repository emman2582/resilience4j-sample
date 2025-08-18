#!/bin/bash

# Simplified cleanup script for all environments

ENVIRONMENT=${1:-local}

case $ENVIRONMENT in
  "local")
    echo "🧹 Cleaning up local deployment..."
    kubectl delete namespace resilience4j-local --ignore-not-found=true
    ;;
  "single")
    echo "🧹 Cleaning up single-node deployment..."
    kubectl delete namespace resilience4j-single --ignore-not-found=true
    ;;
  "multi")
    echo "🧹 Cleaning up multi-node deployment..."
    kubectl delete namespace resilience4j-multi --ignore-not-found=true
    ;;
  "all")
    echo "🧹 Cleaning up all deployments..."
    kubectl delete namespace resilience4j-local --ignore-not-found=true
    kubectl delete namespace resilience4j-single --ignore-not-found=true
    kubectl delete namespace resilience4j-multi --ignore-not-found=true
    ;;
  *)
    echo "Usage: $0 [local|single|multi|all]"
    exit 1
    ;;
esac

echo "✅ Cleanup complete!"