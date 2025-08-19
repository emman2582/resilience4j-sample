#!/bin/bash
echo "Fixing HTTP metrics in Docker deployment..."

echo
echo "1. Rebuilding services with HTTP metrics enabled..."
cd "$(dirname "$0")/../.."
./build.sh

echo
echo "2. Restarting Docker Compose stack..."
docker compose down
docker compose up -d

echo
echo "3. Waiting for services to start..."
sleep 30

echo
echo "4. Testing HTTP metrics availability..."
echo "Checking Service A metrics:"
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_seconds"

echo
echo "Checking Service B metrics:"
curl -s http://localhost:8081/actuator/prometheus | grep "http_server_requests_seconds"

echo
echo "5. Generating some traffic to create metrics..."
curl -s http://localhost:8080/api/a/ok > /dev/null
curl -s http://localhost:8080/api/a/flaky?failRate=10 > /dev/null
curl -s http://localhost:8080/api/a/slow?delayMs=500 > /dev/null

echo
echo "6. Verifying bucket metrics after traffic..."
echo "Service A HTTP bucket metrics:"
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_seconds_bucket"

echo
echo "Service B HTTP bucket metrics:"
curl -s http://localhost:8081/actuator/prometheus | grep "http_server_requests_seconds_bucket"

echo
echo "7. Checking histogram configuration..."
echo "Service A histogram metrics:"
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_seconds{.*quantile"

echo
echo "Service B histogram metrics:"
curl -s http://localhost:8081/actuator/prometheus | grep "http_server_requests_seconds{.*quantile"

echo
echo "HTTP metrics fix complete!"
echo "Check Grafana at http://localhost:3000 for updated dashboards."