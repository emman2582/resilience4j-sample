#!/bin/bash

# Resilience4j Kubernetes Deployment Script
# This script deploys all components in the correct order

echo "🚀 Deploying Resilience4j application to Kubernetes..."

# Determine correct paths based on current directory
if [ -d "../environments" ]; then
    # Running from k8s/scripts/
    ENV_PATH="../environments"
    MANIFEST_PATH="../manifests"
elif [ -d "environments" ]; then
    # Running from k8s/
    ENV_PATH="environments"
    MANIFEST_PATH="manifests"
else
    echo "❌ Cannot find environments directory. Please run from k8s/ or k8s/scripts/"
    exit 1
fi

echo "📁 Using paths: ENV=$ENV_PATH, MANIFEST=$MANIFEST_PATH"

# Create local namespace
echo "📦 Creating local namespace..."
kubectl apply -f $ENV_PATH/namespace-local.yaml

# Load local Docker images into minikube (if using minikube)
if command -v minikube &> /dev/null && minikube status | grep -q "Running"; then
    echo "🐳 Loading local Docker images into minikube..."
    minikube image load r4j-sample-service-a:0.1.0 2>/dev/null || echo "⚠️  Image r4j-sample-service-a:0.1.0 not found locally"
    minikube image load r4j-sample-service-b:0.1.0 2>/dev/null || echo "⚠️  Image r4j-sample-service-b:0.1.0 not found locally"
fi

# Deploy ConfigMaps first (required by deployments)
echo "📋 Creating ConfigMaps..."
kubectl apply -f $MANIFEST_PATH/configs/ -n resilience4j-local

# Deploy services (can be created before deployments)
echo "🌐 Creating Services..."
kubectl apply -f $MANIFEST_PATH/services/ -n resilience4j-local

# Deploy applications in dependency order
echo "📦 Creating Deployments..."
kubectl apply -f $MANIFEST_PATH/deployments/service-b.yaml -n resilience4j-local
kubectl apply -f $MANIFEST_PATH/deployments/service-a.yaml -n resilience4j-local
kubectl apply -f $MANIFEST_PATH/deployments/otel-collector.yaml -n resilience4j-local
kubectl apply -f $MANIFEST_PATH/deployments/prometheus.yaml -n resilience4j-local
kubectl apply -f $MANIFEST_PATH/deployments/grafana.yaml -n resilience4j-local

echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/service-b -n resilience4j-local
kubectl wait --for=condition=available --timeout=300s deployment/service-a -n resilience4j-local
kubectl wait --for=condition=available --timeout=300s deployment/otel-collector -n resilience4j-local
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n resilience4j-local
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n resilience4j-local

echo "✅ All deployments are ready!"
echo ""
echo "📊 Deployment Status:"
kubectl get pods -n resilience4j-local
echo ""
kubectl get services -n resilience4j-local
echo ""
echo "🔗 Next steps:"
echo "  1. Setup port forwarding: ./scripts/port-forward.sh"
echo "  2. Load dashboards: cd ../grafana && ./scripts/load-dashboards-k8s.sh resilience4j-local local"
echo "  3. Test application: curl http://localhost:8080/api/a/ok"