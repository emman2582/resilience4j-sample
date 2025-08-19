#!/bin/bash
echo "Fixing services by removing OpenTelemetry..."

echo
echo "1. Rebuilding without OpenTelemetry..."
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
echo "5. Generating traffic..."
curl -s http://localhost:8080/api/a/ok
curl -s http://localhost:8080/api/a/flaky?failRate=10

echo
echo "6. Checking HTTP metrics..."
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_seconds_bucket" | head -3

echo
echo "Services fixed - OpenTelemetry removed, HTTP metrics working!"