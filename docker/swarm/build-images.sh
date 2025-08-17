#!/bin/bash

# Build Docker images for Swarm deployment

echo "🔨 Building Docker images from project root..."

# Navigate to project root
cd ../../

# Build with Gradle
echo "📦 Building with Gradle..."
./gradlew clean build

if [ $? -ne 0 ]; then
    echo "❌ Gradle build failed"
    exit 1
fi

# Build Docker images
echo "🐳 Building Docker images..."
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

echo "✅ Docker images built successfully"