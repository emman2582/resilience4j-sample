#!/bin/bash

# Load local Docker images into minikube
# This script makes local Docker images available to the Kubernetes cluster

echo "🐳 Loading Docker images into minikube..."

# Check if minikube is running
if ! minikube status | grep -q "Running"; then
    echo "❌ Minikube is not running. Please start it with: minikube start"
    exit 1
fi

# Load the custom application images
echo "📦 Loading service images..."
minikube image load r4j-sample-service-a:0.1.0
minikube image load r4j-sample-service-b:0.1.0

echo "✅ Images loaded successfully!"
echo ""
echo "📋 Available images in minikube:"
minikube image ls | grep r4j-sample