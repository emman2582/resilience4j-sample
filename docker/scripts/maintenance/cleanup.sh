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

# Force remove any remaining containers using our images
echo "🛑 Removing containers..."

# Remove by ancestor (image)
docker ps -a --filter "ancestor=r4j-sample-service-a:0.1.0" -q | xargs -r docker rm -f
docker ps -a --filter "ancestor=r4j-sample-service-b:0.1.0" -q | xargs -r docker rm -f

# Remove by container name patterns
docker ps -a --filter "name=service-a" -q | xargs -r docker rm -f
docker ps -a --filter "name=service-b" -q | xargs -r docker rm -f
docker ps -a --filter "name=prometheus" -q | xargs -r docker rm -f
docker ps -a --filter "name=grafana" -q | xargs -r docker rm -f
docker ps -a --filter "name=otel-collector" -q | xargs -r docker rm -f

# Remove containers from docker-compose project
docker ps -a --filter "label=com.docker.compose.project=docker" -q | xargs -r docker rm -f

# Remove Docker images
echo "🗑️ Removing Docker images..."
docker rmi r4j-sample-service-a:0.1.0 -f || true
docker rmi r4j-sample-service-b:0.1.0 -f || true

# Remove monitoring stack images if they exist
docker rmi prom/prometheus:v2.45.0 -f || true
docker rmi grafana/grafana:10.0.0 -f || true
docker rmi otel/opentelemetry-collector-contrib:0.91.0 -f || true

# Clean up dangling images and volumes
docker image prune -f
docker volume prune -f

# Show remaining containers (for verification)
echo "🔍 Checking for remaining containers..."
REMAINING=$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -E "(service-a|service-b|prometheus|grafana|otel)" || true)
if [ -n "$REMAINING" ]; then
    echo "⚠️  Warning: Some containers still exist:"
    echo "$REMAINING"
    echo "📝 Run './scripts/force-cleanup.sh' if needed"
else
    echo "✅ All project containers removed successfully!"
fi

echo "✅ Docker cleanup completed!"