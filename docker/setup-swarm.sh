#!/bin/bash

# Docker Swarm Setup Script

echo "🐳 Setting up Docker Swarm for autoscaling..."

# Initialize swarm if not already done
if ! docker info | grep -q "Swarm: active"; then
    echo "📦 Initializing Docker Swarm..."
    docker swarm init
fi

# Build images
echo "🔨 Building Docker images..."
cd ..
gradle clean build
docker build -t r4j-sample-service-a:0.1.0 service-a/
docker build -t r4j-sample-service-b:0.1.0 service-b/
cd docker

# Deploy stack
echo "🚀 Deploying stack with scaling..."
docker stack deploy -c docker-compose-swarm.yml r4j-stack

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Show service status
echo "📊 Service status:"
docker service ls

echo "✅ Docker Swarm setup completed!"
echo "🌐 Access points:"
echo "  - Service A (Load Balanced): http://localhost"
echo "  - Service A (Direct): http://localhost:8080"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3000"

echo "🔧 Scale services manually:"
echo "  docker service scale r4j-stack_service-a=3"