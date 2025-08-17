#!/bin/bash

# Diagnose build issues

echo "🔍 Diagnosing build issues..."

echo ""
echo "1. Checking current directory:"
pwd

echo ""
echo "2. Checking if gradlew exists in project root:"
if [ -f "../gradlew" ]; then
    echo "✅ gradlew found at ../gradlew"
else
    echo "❌ gradlew not found at ../gradlew"
    echo "Current directory contents:"
    ls -la ..
fi

echo ""
echo "3. Checking if service directories exist:"
if [ -d "../service-a" ]; then
    echo "✅ service-a directory found"
else
    echo "❌ service-a directory not found"
fi

if [ -d "../service-b" ]; then
    echo "✅ service-b directory found"
else
    echo "❌ service-b directory not found"
fi

echo ""
echo "4. Checking existing Docker images:"
docker images | grep r4j-sample || echo "No r4j-sample images found"

echo ""
echo "5. Checking Docker daemon:"
if docker info >/dev/null 2>&1; then
    echo "✅ Docker daemon is running"
else
    echo "❌ Docker daemon is not running"
fi

echo ""
echo "6. Testing Gradle build manually:"
cd ..
if [ -f "gradlew" ]; then
    echo "Running: ./gradlew clean build"
    ./gradlew clean build
else
    echo "❌ Cannot find gradlew in project root"
fi