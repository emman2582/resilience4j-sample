#!/bin/bash

# Force Docker Cleanup Script
# Use when regular cleanup fails

echo "💥 Force cleaning Docker environment..."

# Stop all running containers
echo "🛑 Stopping all containers..."
docker stop $(docker ps -q) 2>/dev/null || true

# Remove all containers
echo "🗑️ Removing all containers..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

# Remove specific images with force
echo "🔥 Force removing project images..."
docker rmi r4j-sample-service-a:0.1.0 -f 2>/dev/null || true
docker rmi r4j-sample-service-b:0.1.0 -f 2>/dev/null || true

# Clean up everything
echo "🧹 Cleaning up system..."
docker system prune -af --volumes

# Remove Docker Swarm if active
if docker info | grep -q "Swarm: active"; then
    echo "🔄 Leaving Docker Swarm..."
    docker swarm leave --force
fi

echo "✅ Force cleanup completed!"
echo "⚠️  Warning: This removed ALL Docker containers and images!"