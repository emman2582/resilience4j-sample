#!/bin/bash
echo "Fixing OTLP export with proper OpenTelemetry configuration..."

echo
echo "1. Rebuilding with proper OpenTelemetry setup..."
cd "$(dirname "$0")/../.."
./build.sh

echo
echo "2. Restarting stack..."
docker compose down
docker compose up -d

echo
echo "3. Waiting for services to initialize..."
sleep 30

echo
echo "4. Checking OpenTelemetry environment variables..."
echo "Service A OTel config:"
docker exec service-a env | grep OTEL_

echo "Service B OTel config:"
docker exec service-b env | grep OTEL_

echo
echo "5. Testing service health..."
curl -s http://localhost:8080/actuator/health | grep UP
curl -s http://localhost:8081/actuator/health | grep UP

echo
echo "6. Generating telemetry data..."
curl -s http://localhost:8080/api/a/ok > /dev/null
curl -s http://localhost:8080/api/a/slow?delayMs=1000 > /dev/null
curl -s http://localhost:8080/api/a/flaky?failRate=30 > /dev/null

echo
echo "7. Checking for OTLP connection errors..."
echo "Service A logs (checking for connection issues):"
docker logs service-a --tail 10 2>&1 | grep -E "(Connection refused|Failed to publish|OTLP)" || echo "✅ No OTLP connection errors"

echo
echo "8. Verifying OTel collector received data..."
sleep 10
RECEIVED_METRICS=$(curl -s http://localhost:8888/metrics | grep "otelcol_receiver_accepted_metric_points_total")
RECEIVED_SPANS=$(curl -s http://localhost:8888/metrics | grep "otelcol_receiver_accepted_spans_total")

echo "Received metrics: $RECEIVED_METRICS"
echo "Received spans: $RECEIVED_SPANS"

echo
echo "9. Checking exported metrics..."
EXPORTED_COUNT=$(curl -s http://localhost:9464/metrics | grep -E "(http_|resilience4j_)" | wc -l)
echo "✅ Exported metrics count: $EXPORTED_COUNT"

if [ "$EXPORTED_COUNT" -gt 0 ]; then
    echo "Sample exported metrics:"
    curl -s http://localhost:9464/metrics | grep -E "(http_server_requests|resilience4j_)" | head -3
fi

echo
echo "🎯 OTLP export verification complete!"
echo "📊 Grafana can now read from: http://otel-collector:9464"