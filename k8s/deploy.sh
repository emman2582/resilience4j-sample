#!/bin/bash

# Resilience4j Kubernetes Deployment Script
# This script deploys all components in the correct order

echo "🚀 Deploying Resilience4j application to Kubernetes..."

# Create local namespace
echo "📦 Creating local namespace..."
kubectl apply -f namespace-local.yaml

# Load local Docker images into minikube (if using minikube)
if command -v minikube &> /dev/null && minikube status | grep -q "Running"; then
    echo "🐳 Loading local Docker images into minikube..."
    minikube image load r4j-sample-service-a:0.1.0 2>/dev/null || echo "⚠️  Image r4j-sample-service-a:0.1.0 not found locally"
    minikube image load r4j-sample-service-b:0.1.0 2>/dev/null || echo "⚠️  Image r4j-sample-service-b:0.1.0 not found locally"
fi

# Deploy ConfigMaps first (required by deployments)
echo "📋 Creating ConfigMaps..."
kubectl apply -f configs/ -n resilience4j-local

# Deploy services (can be created before deployments)
echo "🌐 Creating Services..."
kubectl apply -f services/ -n resilience4j-local

# Deploy applications in dependency order
echo "📦 Creating Deployments..."
kubectl apply -f deployments/service-b.yaml -n resilience4j-local
kubectl apply -f deployments/service-a.yaml -n resilience4j-local
kubectl apply -f deployments/otel-collector.yaml -n resilience4j-local
kubectl apply -f deployments/prometheus.yaml -n resilience4j-local
kubectl apply -f deployments/grafana.yaml -n resilience4j-local

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
echo "🔗 To access services locally, run:"
echo "kubectl port-forward svc/service-a 8080:8080 -n resilience4j-local &"
echo "kubectl port-forward svc/grafana 3000:3000 -n resilience4j-local &"
echo "kubectl port-forward svc/prometheus 9090:9090 -n resilience4j-local &"
echo ""
echo "🧪 Test the application:"
echo "curl http://localhost:8080/api/a/ok"