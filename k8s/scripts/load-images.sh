#!/bin/bash

# Load local Docker images into minikube

echo "🐳 Loading Docker images into minikube..."

# Check if minikube is running
if ! minikube status | grep -q "Running"; then
    echo "❌ Minikube is not running. Please start it with: minikube start"
    exit 1
fi

# Check if images exist locally
echo "🔍 Checking local images..."
echo "All r4j-sample images:"
docker images | grep r4j-sample || echo "No r4j-sample images found"

echo ""
echo "Looking for specific images:"
SERVICE_A_IMAGE=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep "r4j-sample-service-a:0.1.0" || echo "")
SERVICE_B_IMAGE=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep "r4j-sample-service-b:0.1.0" || echo "")

if [ -z "$SERVICE_A_IMAGE" ]; then
    echo "❌ Image r4j-sample-service-a:0.1.0 not found"
    echo "Available service-a images:"
    docker images | grep "r4j-sample-service-a" || echo "None"
    echo "💡 Run: ./scripts/build-images.sh first"
    exit 1
else
    echo "✅ Found: $SERVICE_A_IMAGE"
fi

if [ -z "$SERVICE_B_IMAGE" ]; then
    echo "❌ Image r4j-sample-service-b:0.1.0 not found"
    echo "Available service-b images:"
    docker images | grep "r4j-sample-service-b" || echo "None"
    echo "💡 Run: ./scripts/build-images.sh first"
    exit 1
else
    echo "✅ Found: $SERVICE_B_IMAGE"
fi

# Load the custom application images
echo "📦 Loading service images..."
minikube image load r4j-sample-service-a:0.1.0
minikube image load r4j-sample-service-b:0.1.0

echo "✅ Images loaded successfully!"
echo ""
echo "📋 Available images in minikube:"
minikube image ls | grep r4j-sample