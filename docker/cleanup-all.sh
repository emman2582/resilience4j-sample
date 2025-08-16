#!/bin/bash

# Master Cleanup Script for entire Resilience4j project

echo "🧹 Master cleanup for Resilience4j project..."

# Stop all background processes
echo "🔌 Stopping all background processes..."
pkill -f "gradle.*bootRun" || true
pkill -f "kubectl port-forward" || true
pkill -f "minikube" || true

# Cleanup Docker containers and images
echo "🐳 Cleaning up Docker resources..."
docker stop $(docker ps -q --filter "ancestor=r4j-sample-service-a:0.1.0") 2>/dev/null || true
docker stop $(docker ps -q --filter "ancestor=r4j-sample-service-b:0.1.0") 2>/dev/null || true
docker rm $(docker ps -aq --filter "ancestor=r4j-sample-service-a:0.1.0") 2>/dev/null || true
docker rm $(docker ps -aq --filter "ancestor=r4j-sample-service-b:0.1.0") 2>/dev/null || true

# Docker Compose cleanup
echo "🐳 Cleaning up Docker Compose..."
cd docker
docker compose down --volumes --remove-orphans || true
cd ..

# Kubernetes cleanup
echo "☸️ Cleaning up Kubernetes resources..."
./k8s/cleanup.sh || true

# Helm cleanup  
echo "⎈ Cleaning up Helm resources..."
./helm/cleanup.sh || true

# Minikube cleanup
if command -v minikube &> /dev/null; then
    echo "🔄 Cleaning up Minikube..."
    minikube delete || true
fi

# Gradle cleanup
echo "🏗️ Cleaning up Gradle cache..."
./gradlew clean || true
rm -rf .gradle/daemon || true

# NodeJS cleanup
echo "📦 Cleaning up NodeJS..."
cd nodejs-client
rm -rf node_modules || true
rm -f package-lock.json || true
cd ..

# Clean up temporary files
echo "🗑️ Cleaning up temporary files..."
find . -name "*.log" -delete || true
find . -name "nohup.out" -delete || true
rm -f k8s/*-aws.yaml || true
rm -f k8s/ingress-aws.yaml || true

echo "✅ Master cleanup completed!"
echo "📊 Remaining Docker images:"
docker images | grep r4j-sample || echo "No r4j-sample images found"
echo "📊 Remaining Kubernetes namespaces:"
kubectl get namespaces | grep resilience4j || echo "No resilience4j namespaces found"