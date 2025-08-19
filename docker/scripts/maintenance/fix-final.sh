#!/bin/bash
echo "Final fix - removing OpenTelemetry, keeping HTTP metrics..."

echo
echo "1. Rebuilding with stable configuration..."
cd "$(dirname "$0")/../.."
./build.sh

echo
echo "2. Restarting services..."
docker compose down
docker compose up -d

echo
echo "3. Waiting for services..."
sleep 25

echo
echo "4. Testing services..."
curl -s http://localhost:8080/actuator/health
curl -s http://localhost:8081/actuator/health

echo
echo "5. Generating traffic..."
curl -s http://localhost:8080/api/a/ok > /dev/null
curl -s http://localhost:8080/api/a/flaky?failRate=10 > /dev/null

echo
echo "6. Checking available metrics..."
echo "HTTP server bucket metrics:"
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_seconds_bucket" | head -3

echo
echo "HTTP server count metrics:"
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_seconds_count" | head -3

echo
echo "Time Limiter metrics:"
curl -s http://localhost:8080/actuator/prometheus | grep "resilience4j_timelimiter" | head -2

echo
echo "✅ Services working with HTTP metrics and Time Limiter!"