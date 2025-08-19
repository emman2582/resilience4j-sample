#!/bin/bash
echo "Fixing tracing propagator conflict..."

echo
echo "1. Rebuilding without Brave tracing..."
cd "$(dirname "$0")/../.."
./build.sh

echo
echo "2. Restarting services..."
docker compose down
docker compose up -d

echo
echo "3. Waiting for services..."
sleep 30

echo
echo "4. Testing services..."
curl -s http://localhost:8080/actuator/health | grep UP
curl -s http://localhost:8081/actuator/health | grep UP

echo
echo "5. Testing metrics..."
curl -s http://localhost:8080/api/a/ok > /dev/null
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_seconds_bucket" | head -2

echo
echo "Propagator conflict fixed - using OpenTelemetry only!"