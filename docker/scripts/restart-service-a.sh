#!/bin/bash

echo "🔄 Restarting Service A with updated bulkhead implementation..."

# Stop existing service-a container
docker stop service-a 2>/dev/null || true
docker rm service-a 2>/dev/null || true

# Rebuild image
docker build -t r4j-sample-service-a:0.1.0 service-a/

# Restart with docker-compose
docker compose up -d service-a

echo "✅ Service A restarted!"
echo ""
echo "🧪 Test the bulkhead endpoints:"
echo "curl http://localhost:8080/api/a/bulkhead/info"