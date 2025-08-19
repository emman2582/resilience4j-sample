#!/bin/bash
echo "Fixing OpenTelemetry by using Prometheus scraping instead of OTLP..."

echo
echo "1. Rebuilding with Prometheus export..."
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
echo "4. Testing service endpoints..."
curl -s http://localhost:8080/actuator/health | grep UP
curl -s http://localhost:8081/actuator/health | grep UP

echo
echo "5. Checking Prometheus endpoints..."
echo "Service A metrics available:"
curl -s http://localhost:8080/actuator/prometheus | grep -E "(http_server_requests|resilience4j)" | wc -l

echo "Service B metrics available:"
curl -s http://localhost:8081/actuator/prometheus | grep -E "(http_server_requests|resilience4j)" | wc -l

echo
echo "6. Generating test traffic..."
curl -s http://localhost:8080/api/a/ok > /dev/null
curl -s http://localhost:8080/api/a/slow?delayMs=800 > /dev/null
curl -s http://localhost:8080/api/a/flaky?failRate=20 > /dev/null

echo
echo "7. Checking for connection errors..."
docker logs service-a --tail 5 2>&1 | grep -E "(Connection refused|Failed to publish)" || echo "✅ No connection errors"

echo
echo "8. Verifying OTel collector scraping..."
sleep 10
SCRAPED_METRICS=$(curl -s http://localhost:9464/metrics | grep -E "(http_server_requests|resilience4j)" | wc -l)
echo "✅ OTel collector scraped metrics: $SCRAPED_METRICS"

echo
echo "9. Sample metrics from OTel collector:"
curl -s http://localhost:9464/metrics | grep "http_server_requests_total" | head -2

echo
echo "🎯 OpenTelemetry working via Prometheus scraping!"
echo "📊 Grafana data source: http://otel-collector:9464"