#!/bin/bash
echo "🔧 Fixing Grafana metrics data..."

echo
echo "1. Generating traffic to create HTTP metrics..."
for i in {1..20}; do
    curl -s http://localhost:8080/api/a/ok > /dev/null
    curl -s http://localhost:8080/api/a/slow?delayMs=500 > /dev/null
    curl -s http://localhost:8080/api/a/flaky?failRate=30 > /dev/null
done

echo
echo "2. Checking direct service metrics..."
HTTP_METRICS=$(curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_total" | wc -l)
echo "Service A HTTP metrics: $HTTP_METRICS"

if [ "$HTTP_METRICS" -eq 0 ]; then
    echo "❌ No HTTP metrics from service - checking configuration..."
    docker logs service-a --tail 10
    exit 1
fi

echo
echo "3. Checking Prometheus scraping..."
sleep 10
PROM_HTTP=$(curl -s "http://localhost:9090/api/v1/query?query=http_server_requests_total" | grep -o '"result":\[[^]]*\]')
echo "Prometheus HTTP metrics: $PROM_HTTP"

echo
echo "4. Checking OTel Collector metrics..."
OTEL_SPANS=$(curl -s http://localhost:8888/metrics | grep "otelcol_receiver_accepted_spans_total")
echo "OTel spans: $OTEL_SPANS"

echo
echo "5. Testing Grafana data source..."
curl -s "http://admin:admin@localhost:3000/api/datasources/proxy/1/api/v1/query?query=up"

echo
echo "6. Fixing Grafana data source if needed..."
curl -X DELETE http://admin:admin@localhost:3000/api/datasources/1 2>/dev/null

curl -X POST \
  http://admin:admin@localhost:3000/api/datasources \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090",
    "access": "proxy",
    "isDefault": true
  }'

echo
echo "7. Testing specific metrics in Grafana..."
sleep 5
echo "Testing http_server_requests_total:"
curl -s "http://admin:admin@localhost:3000/api/datasources/proxy/1/api/v1/query?query=http_server_requests_total"

echo
echo "Testing otelcol metrics:"
curl -s "http://admin:admin@localhost:3000/api/datasources/proxy/1/api/v1/query?query=otelcol_process_uptime"

echo
echo "✅ Grafana metrics should now work!"
echo "📊 Dashboard: http://localhost:3000/d/otel-sli-slo-dashboard"