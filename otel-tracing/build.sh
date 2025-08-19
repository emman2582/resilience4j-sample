#!/bin/bash

# Build OTel-enabled services

echo "🔨 Building services..."
cd ..
./gradlew clean build

echo "🐳 Building OTel Docker images..."
cd otel-tracing

docker build -t r4j-service-a-otel:latest -f ../service-a/Dockerfile.otel ../service-a/
docker build -t r4j-service-b-otel:latest -f ../service-b/Dockerfile.otel ../service-b/
docker compose restart service-a service-b

echo "✅ Build complete!"
echo "🚀 Run: docker compose up -d"