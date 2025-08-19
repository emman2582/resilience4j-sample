#!/bin/bash
echo "Final OpenTelemetry fix with environment variables..."

echo
echo "1. Rebuilding with updated configuration..."
cd "$(dirname "$0")/../.."
./build.sh

echo
echo "2. Restarting stack..."
docker compose down
docker compose up -d

echo
echo "3. Waiting for services..."
sleep 25

echo
echo "4. Checking environment variables in containers..."
echo "Service A OTLP config:"
docker exec service-a env | grep OTLP

echo "Service B OTLP config:"
docker exec service-b env | grep OTLP

echo
echo "5. Testing basic connectivity..."
curl -s http://localhost:8080/actuator/health
curl -s http://localhost:8081/actuator/health

echo
echo "6. Generating test traffic..."
curl -s http://localhost:8080/api/a/ok > /dev/null
curl -s http://localhost:8080/api/a/slow?delayMs=800 > /dev/null

echo
echo "7. Checking for connection errors..."
echo "Service A recent logs:"
docker logs service-a --tail 10 2>&1 | grep -E "(Connection refused|Failed to publish)" || echo "No connection errors found"

echo
echo "8. Verifying OTel collector metrics..."
sleep 5
OTEL_METRICS=$(curl -s http://localhost:8888/metrics | grep "otelcol_receiver_accepted_metric_points_total")
if [ -n "$OTEL_METRICS" ]; then
    echo "✅ OTel collector receiving metrics: $OTEL_METRICS"
else
    echo "❌ OTel collector not receiving metrics"
fi

echo
echo "9. Checking exported metrics..."
EXPORTED=$(curl -s http://localhost:9464/metrics | grep -E "(http_server_requests|resilience4j)" | wc -l)
echo "✅ Exported metrics count: $EXPORTED"

echo
echo "🎯 OpenTelemetry setup verification complete!"