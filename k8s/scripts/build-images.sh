#!/bin/bash

# Build Docker images for Kubernetes deployment

echo "🔨 Building Docker images for Kubernetes..."

# Navigate to project root
cd ..

echo ""
echo "1. Building with Gradle..."
./gradlew clean build

if [ $? -ne 0 ]; then
    echo "❌ Gradle build failed"
    echo "💡 Try running: ./fix-gradle-build.sh"
    exit 1
fi

echo ""
echo "2. Building Docker images..."
docker build -t r4j-sample-service-a:0.1.0 service-a/
if [ $? -ne 0 ]; then
    echo "❌ Failed to build service-a image"
    exit 1
fi

docker build -t r4j-sample-service-b:0.1.0 service-b/
if [ $? -ne 0 ]; then
    echo "❌ Failed to build service-b image"
    exit 1
fi

echo ""
echo "✅ Docker images built successfully!"
echo "📋 Available images:"
docker images | grep r4j-sample