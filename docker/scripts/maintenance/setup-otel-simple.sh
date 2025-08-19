#!/bin/bash
echo "Setting up minimal OpenTelemetry with direct Grafana integration..."

echo
echo "1. Building with OpenTelemetry 1.32.0..."
cd "$(dirname "$0")/../.."
./build.sh

echo
echo "2. Starting stack..."
docker compose down
docker compose up -d

echo
echo "3. Waiting for services..."
sleep 30

echo
echo "4. Testing services..."
curl -s http://localhost:8080/actuator/health
curl -s http://localhost:8081/actuator/health

echo
echo "5. Generating telemetry data..."
curl -s http://localhost:8080/api/a/ok > /dev/null
curl -s http://localhost:8080/api/a/slow?delayMs=1000 > /dev/null
curl -s http://localhost:8080/api/a/flaky?failRate=20 > /dev/null

echo
echo "6. Checking OTel collector metrics..."
curl -s http://localhost:9464/metrics | grep -E "(http_|otelcol_)" | head -5

echo
echo "✅ OpenTelemetry setup complete!"
echo "- Services export directly to OTel Collector"
echo "- Minimal logging (WARN level only)"
echo "- Grafana can read from: http://otel-collector:9464/metrics"
echo "- No Prometheus dependency needed"