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
./build-images.sh

if [ $? -ne 0 ]; then
    echo "❌ Failed to build images"
    exit 1
fi

# Deploy stack
echo "🚀 Deploying stack with scaling..."
docker stack deploy -c docker-compose-swarm.yml r4j-stack

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Show service status
echo "📊 Service status:"
docker service ls

# Fix metrics collection for Swarm
echo "🔧 Setting up metrics collection..."
sleep 10
./fix-swarm-metrics.sh

echo "✅ Docker Swarm setup completed!"
echo "🌐 Access points:"
echo "  - Service A (Load Balanced): http://localhost"
echo "  - Service A (Direct): http://localhost:8080"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3000"

echo "🔧 Scale services manually:"
echo "  docker service scale r4j-stack_service-a=3"
echo "📈 Load dashboards:"
echo "  cd ../grafana && ./scripts/load-dashboards.sh"