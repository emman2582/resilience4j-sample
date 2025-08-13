#!/bin/bash

# Resilience4j Kubernetes Deployment Script
# This script deploys all components in the correct order

echo "🚀 Deploying Resilience4j application to Kubernetes..."

# Load local Docker images into minikube (if using minikube)
if command -v minikube &> /dev/null && minikube status | grep -q "Running"; then
    echo "🐳 Loading local Docker images into minikube..."
    minikube image load r4j-sample-service-a:0.1.0 2>/dev/null || echo "⚠️  Image r4j-sample-service-a:0.1.0 not found locally"
    minikube image load r4j-sample-service-b:0.1.0 2>/dev/null || echo "⚠️  Image r4j-sample-service-b:0.1.0 not found locally"
fi

# Deploy ConfigMaps first (required by deployments)
echo "📋 Creating ConfigMaps..."
kubectl apply -f configs/

# Deploy services (can be created before deployments)
echo "🌐 Creating Services..."
kubectl apply -f services/

# Deploy applications in dependency order
echo "📦 Creating Deployments..."
kubectl apply -f deployments/service-b.yaml
kubectl apply -f deployments/service-a.yaml
kubectl apply -f deployments/otel-collector.yaml
kubectl apply -f deployments/prometheus.yaml
kubectl apply -f deployments/grafana.yaml

echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/service-b
kubectl wait --for=condition=available --timeout=300s deployment/service-a
kubectl wait --for=condition=available --timeout=300s deployment/otel-collector
kubectl wait --for=condition=available --timeout=300s deployment/prometheus
kubectl wait --for=condition=available --timeout=300s deployment/grafana

echo "✅ All deployments are ready!"
echo ""
echo "📊 Deployment Status:"
kubectl get pods
echo ""
kubectl get services
echo ""
echo "🔗 To access services locally, run:"
echo "kubectl port-forward svc/service-a 8080:8080 &"
echo "kubectl port-forward svc/grafana 3000:3000 &"
echo "kubectl port-forward svc/prometheus 9090:9090 &"
echo ""
echo "🧪 Test the application:"
echo "curl http://localhost:8080/api/a/ok"