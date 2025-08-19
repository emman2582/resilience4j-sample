#!/bin/bash
echo "Fixing OpenTelemetry connection issues..."

echo
echo "1. Rebuilding services..."
cd "$(dirname "$0")/../.."
./build.sh

echo
echo "2. Restarting stack..."
docker compose down
docker compose up -d

echo
echo "3. Waiting for OTel collector..."
sleep 20

echo
echo "4. Checking OTel collector health..."
curl -s http://localhost:8888/metrics | grep otelcol_process_uptime

echo
echo "5. Testing service connectivity..."
curl -s http://localhost:8080/actuator/health
curl -s http://localhost:8081/actuator/health

echo
echo "6. Generating metrics..."
curl -s http://localhost:8080/api/a/ok > /dev/null
curl -s http://localhost:8080/api/a/slow?delayMs=500 > /dev/null

echo
echo "7. Checking exported metrics..."
curl -s http://localhost:9464/metrics | grep -E "(http_|resilience4j_)" | head -3

echo
echo "✅ OpenTelemetry connection fixed!"