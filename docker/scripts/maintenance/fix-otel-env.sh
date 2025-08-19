#!/bin/bash
echo "Fixing OpenTelemetry environment variables..."

echo
echo "1. Restarting stack with correct OTLP endpoints..."
cd "$(dirname "$0")/../.."
docker compose down
docker compose up -d

echo
echo "2. Waiting for services to start..."
sleep 30

echo
echo "3. Checking service logs for connection errors..."
echo "Service A logs:"
docker logs service-a 2>&1 | grep -E "(WARN|ERROR)" | tail -3

echo "Service B logs:"
docker logs service-b 2>&1 | grep -E "(WARN|ERROR)" | tail -3

echo
echo "4. Testing connectivity..."
curl -s http://localhost:8080/actuator/health | grep UP
curl -s http://localhost:8081/actuator/health | grep UP

echo
echo "5. Generating metrics..."
curl -s http://localhost:8080/api/a/ok > /dev/null
curl -s http://localhost:8080/api/a/slow?delayMs=500 > /dev/null

echo
echo "6. Checking OTel collector received metrics..."
sleep 5
curl -s http://localhost:8888/metrics | grep "otelcol_receiver_accepted_metric_points_total"

echo
echo "7. Checking exported metrics..."
curl -s http://localhost:9464/metrics | grep -E "(http_server_requests|resilience4j)" | head -3

echo
echo "✅ OpenTelemetry environment fix complete!"