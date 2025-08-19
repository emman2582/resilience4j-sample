#!/bin/bash
echo "🔍 Debugging OTLP Export Issue..."

echo
echo "1. Checking OTel Collector endpoints:"
echo "Port 8888 (internal metrics):"
curl -s http://localhost:8888/metrics | grep -E "(otelcol_receiver|otelcol_exporter)" | head -5

echo
echo "Port 9464 (Prometheus export):"
EXPORTED_METRICS=$(curl -s http://localhost:9464/metrics | wc -l)
echo "Lines of metrics: $EXPORTED_METRICS"

if [ "$EXPORTED_METRICS" -lt 10 ]; then
    echo "❌ No application metrics exported - OTLP not working"
else
    echo "✅ Application metrics exported"
fi

echo
echo "2. Checking service environment variables:"
echo "Service A OTEL config:"
docker exec service-a env | grep OTEL_ || echo "No OTEL environment variables found"

echo
echo "Service B OTEL config:"
docker exec service-b env | grep OTEL_ || echo "No OTEL environment variables found"

echo
echo "3. Checking service logs for OTLP errors:"
echo "Service A OTLP logs:"
docker logs service-a --tail 20 2>&1 | grep -i "otlp\|otel\|export" || echo "No OTLP logs found"

echo
echo "4. Testing OTel Collector OTLP endpoint:"
echo "Testing if collector accepts OTLP on port 4318:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:4318/v1/metrics

echo
echo "5. Checking if services have OTLP dependencies:"
echo "Service A dependencies:"
docker exec service-a find /app -name "*.jar" -exec jar tf {} \; | grep -i "opentelemetry" | head -3

echo
echo "🔧 Diagnosis:"
if docker exec service-a env | grep -q "OTEL_EXPORTER_OTLP_ENDPOINT"; then
    echo "✅ Environment variables set"
else
    echo "❌ OTEL environment variables missing"
fi

if docker logs service-a --tail 50 2>&1 | grep -q "otlp\|OpenTelemetry"; then
    echo "✅ OTLP activity in logs"
else
    echo "❌ No OTLP activity in service logs"
fi