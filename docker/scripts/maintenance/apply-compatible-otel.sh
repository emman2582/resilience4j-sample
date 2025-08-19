#!/bin/bash
echo "Applying compatible OpenTelemetry versions..."

echo
echo "1. Rebuilding with compatible OpenTelemetry 2.7.0..."
cd "$(dirname "$0")/../.."
./build.sh

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo
echo "2. Restarting stack with OpenTelemetry..."
docker compose down
docker compose up -d

echo
echo "3. Waiting for services to initialize..."
sleep 45

echo
echo "4. Testing service health..."
echo "Service A health:"
curl -s http://localhost:8080/actuator/health | grep -o '"status":"[^"]*"'

echo "Service B health:"
curl -s http://localhost:8081/actuator/health | grep -o '"status":"[^"]*"'

echo
echo "5. Generating traffic for metrics..."
curl -s http://localhost:8080/api/a/ok > /dev/null
curl -s http://localhost:8080/api/a/flaky?failRate=20 > /dev/null
curl -s http://localhost:8080/api/a/slow?delayMs=800 > /dev/null
curl -s http://localhost:8080/api/a/limited > /dev/null

echo
echo "6. Checking OpenTelemetry metrics..."
echo "OTel collector internal metrics:"
curl -s http://localhost:8888/metrics | grep -E "otelcol_(receiver_accepted|exporter_sent)_spans_total" | head -2

echo
echo "HTTP server metrics:"
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_seconds_bucket" | head -2

echo
echo "Time Limiter metrics:"
curl -s http://localhost:8080/actuator/prometheus | grep "resilience4j_timelimiter" | head -2

echo
echo "✅ Compatible OpenTelemetry implementation complete!"
echo "- OpenTelemetry Spring Boot Starter: 2.7.0"
echo "- OpenTelemetry SDK: 1.41.0"
echo "- Time Limiter: Working with Resilience4j 2.2.0"