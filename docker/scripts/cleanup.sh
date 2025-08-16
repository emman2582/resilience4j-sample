#!/bin/bash

# Docker Compose Cleanup Script

echo "🧹 Cleaning up Docker Compose deployment..."

# Stop and remove containers, networks, volumes
docker compose down --volumes --remove-orphans

# Clean up Docker Swarm if active
if docker info | grep -q "Swarm: active"; then
    echo "🔄 Cleaning up Docker Swarm..."
    docker stack rm r4j-stack || true
    sleep 10
fi

# Remove Docker images
echo "🗑️ Removing Docker images..."
docker rmi r4j-sample-service-a:0.1.0 || true
docker rmi r4j-sample-service-b:0.1.0 || true

# Clean up dangling images and volumes
docker image prune -f
docker volume prune -f

echo "✅ Docker cleanup completed!"