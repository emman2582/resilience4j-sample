#!/bin/bash

# Start and configure minikube for local development

echo "🚀 Starting minikube for local development..."

# Check if minikube is already running
if minikube status | grep -q "Running"; then
    echo "✅ Minikube is already running"
    minikube status
    exit 0
fi

# Start minikube with recommended resources
echo "🔧 Starting minikube with recommended settings..."
minikube start --memory=4096 --cpus=2 --driver=docker

# Wait for minikube to be ready
echo "⏳ Waiting for minikube to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Enable required addons
echo "🔌 Enabling required addons..."
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

echo "✅ Minikube is ready!"
echo ""
echo "📊 Cluster info:"
kubectl cluster-info
echo ""
echo "🏃 Node status:"
kubectl get nodes
echo ""
echo "💡 Next steps:"
echo "  1. Build images: ./scripts/build-images.sh"
echo "  2. Load images: ./scripts/load-images.sh"
echo "  3. Deploy: ./scripts/deploy.sh"
echo "  4. Access dashboard: minikube dashboard"