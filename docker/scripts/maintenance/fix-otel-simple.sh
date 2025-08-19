#!/bin/bash
echo "Fixing OpenTelemetry compatibility and rebuilding..."

echo
echo "1. Rebuilding with compatible OpenTelemetry versions..."
cd "$(dirname "$0")/../.."
./build.sh

echo
echo "2. Restarting services..."
docker compose restart service-a service-b

echo
echo "3. Waiting for services to start..."
sleep 20

echo
echo "4. Testing basic connectivity..."
curl -s http://localhost:8080/actuator/health
curl -s http://localhost:8081/actuator/health

echo
echo "5. Generating traffic..."
curl -s http://localhost:8080/api/a/ok
curl -s http://localhost:8080/api/a/flaky?failRate=10

echo
echo "6. Checking metrics..."
curl -s http://localhost:8080/actuator/prometheus | grep -E "http_server_requests_seconds_(count|bucket)" | head -5

echo
echo "OpenTelemetry fix complete!"