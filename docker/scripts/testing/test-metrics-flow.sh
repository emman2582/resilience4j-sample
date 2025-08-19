#!/bin/bash
echo "🔍 Testing complete metrics flow..."

echo
echo "Step 1: Service → Prometheus endpoint"
curl -s http://localhost:8080/api/a/ok > /dev/null
sleep 2
SERVICE_METRICS=$(curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_total" | head -1)
echo "✓ Service metrics: $SERVICE_METRICS"

echo
echo "Step 2: Prometheus → Scraping"
PROM_TARGETS=$(curl -s http://localhost:9090/api/v1/targets | grep -c '"health":"up"')
echo "✓ Prometheus healthy targets: $PROM_TARGETS"

echo
echo "Step 3: Prometheus → Query"
PROM_QUERY=$(curl -s "http://localhost:9090/api/v1/query?query=http_server_requests_total" | grep -c '"value"')
echo "✓ Prometheus query results: $PROM_QUERY"

echo
echo "Step 4: Grafana → Data source"
GRAFANA_DS=$(curl -s "http://admin:admin@localhost:3000/api/datasources/proxy/1/api/v1/query?query=up" | grep -c '"value"')
echo "✓ Grafana data source results: $GRAFANA_DS"

echo
echo "Step 5: OTel Collector internal"
OTEL_UPTIME=$(curl -s http://localhost:8888/metrics | grep "otelcol_process_uptime")
echo "✓ OTel Collector: $OTEL_UPTIME"

if [ "$PROM_QUERY" -gt 0 ] && [ "$GRAFANA_DS" -gt 0 ]; then
    echo "✅ Metrics flow working - check dashboard panels"
else
    echo "❌ Metrics flow broken - check configuration"
fi