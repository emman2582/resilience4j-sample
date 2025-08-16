#!/bin/bash

# Complete project cleanup script
# Cleans all deployment targets and build artifacts

echo "🧹 Starting complete project cleanup..."

# Docker cleanup
echo "🐳 Cleaning Docker resources..."
cd docker
if [ -f "scripts/cleanup.sh" ]; then
    ./scripts/cleanup.sh
else
    echo "⚠️  Docker cleanup script not found"
fi
cd ..

# Kubernetes cleanup
echo "☸️  Cleaning Kubernetes resources..."
cd k8s
if [ -f "cleanup.sh" ]; then
    ./cleanup.sh
else
    echo "⚠️  Kubernetes cleanup script not found"
fi
cd ..

# Helm cleanup
echo "⎈ Cleaning Helm resources..."
cd helm
if [ -f "cleanup.sh" ]; then
    ./cleanup.sh
else
    echo "⚠️  Helm cleanup script not found"
fi
cd ..

# AWS Lambda cleanup
echo "λ Cleaning AWS Lambda resources..."
cd aws-lambda
if [ -f "scripts/cleanup-containers.sh" ]; then
    ./scripts/cleanup-containers.sh
else
    echo "⚠️  AWS Lambda cleanup script not found"
fi
cd ..

# NodeJS client cleanup
echo "📦 Cleaning NodeJS client..."
cd nodejs-client
if [ -d "node_modules" ]; then
    rm -rf node_modules
    echo "   Removed node_modules"
fi
if [ -f "package-lock.json" ]; then
    rm package-lock.json
    echo "   Removed package-lock.json"
fi
if [ -f ".env" ]; then
    rm .env
    echo "   Removed .env file"
fi
cd ..

# Gradle cleanup
echo "🏗️  Cleaning Gradle build artifacts..."
if command -v gradle &> /dev/null; then
    gradle clean
    echo "   Gradle clean completed"
else
    echo "⚠️  Gradle not found, skipping build cleanup"
fi

# Docker images cleanup
echo "🗑️  Cleaning Docker images..."
docker rmi r4j-sample-service-a:0.1.0 2>/dev/null || echo "   Service A image not found"
docker rmi r4j-sample-service-b:0.1.0 2>/dev/null || echo "   Service B image not found"

echo "✅ Complete project cleanup finished!"
echo ""
echo "📋 What was cleaned:"
echo "   • Docker containers and images"
echo "   • Kubernetes deployments and services"
echo "   • Helm releases"
echo "   • AWS Lambda functions and ECR repositories"
echo "   • NodeJS dependencies and cache"
echo "   • Gradle build artifacts"
echo ""
echo "🚀 Ready for fresh deployment!"