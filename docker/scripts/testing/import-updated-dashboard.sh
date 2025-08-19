#!/bin/bash
echo "📊 Importing Updated OpenTelemetry SLI/SLO Dashboard..."

echo
echo "1. Removing old dashboard..."
curl -X DELETE http://admin:admin@localhost:3000/api/dashboards/uid/otel-e2e-transactions 2>/dev/null

echo
echo "2. Importing updated dashboard..."
DASHBOARD_JSON=$(cat "$(dirname "$0")/../../dashboards/grafana-dashboard-opentelemetry.json")

IMPORT_RESULT=$(curl -X POST \
  http://admin:admin@localhost:3000/api/dashboards/db \
  -H 'Content-Type: application/json' \
  -d "{\"dashboard\": $DASHBOARD_JSON, \"overwrite\": true}" 2>/dev/null)

echo "✅ Dashboard imported"

echo
echo "3. Generating comprehensive test data..."
echo "   Creating SLI/SLO test scenarios..."

# Generate varied traffic for SLI metrics
for i in {1..30}; do
    # Success requests (for availability SLI)
    curl -s http://localhost:8080/api/a/ok > /dev/null
    
    # Latency variations (for latency SLI)
    if [ $((i % 3)) -eq 0 ]; then
        curl -s "http://localhost:8080/api/a/slow?delayMs=800" > /dev/null
    fi
    
    # Error scenarios (for error rate SLI)
    if [ $((i % 7)) -eq 0 ]; then
        curl -s "http://localhost:8080/api/a/flaky?failRate=90" > /dev/null
    fi
    
    # TimeLimiter scenarios
    if [ $((i % 5)) -eq 0 ]; then
        curl -s "http://localhost:8080/api/a/slow?delayMs=3000" > /dev/null
    fi
    
    # Rate limiter and bulkhead
    if [ $((i % 4)) -eq 0 ]; then
        curl -s http://localhost:8080/api/a/limited > /dev/null
        curl -s http://localhost:8080/api/a/bulkhead/x > /dev/null &
    fi
    
    sleep 0.3
done

echo "✅ Test data generated"

echo
echo "4. Waiting for metrics to populate..."
sleep 15

echo
echo "5. Verifying dashboard metrics..."
METRICS_COUNT=$(curl -s http://localhost:9090/api/v1/label/__name__/values | grep -E "(http_server_requests|resilience4j_|otelcol_)" | wc -l)
echo "   Available metrics: $METRICS_COUNT"

echo
echo "6. Testing key SLI queries..."
echo "   Request Rate:"
curl -s "http://localhost:9090/api/v1/query?query=rate(http_server_requests_total[5m])" | grep -o '"value":\[[^]]*\]' | head -2

echo "   Error Rate:"
curl -s "http://localhost:9090/api/v1/query?query=rate(http_server_requests_total{status=~\"5..\"}[5m])" | grep -o '"value":\[[^]]*\]' | head -1

echo "   P95 Latency:"
curl -s "http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,rate(http_server_requests_seconds_bucket[5m]))" | grep -o '"value":\[[^]]*\]' | head -1

echo
echo "🎯 Updated Dashboard Ready!"
echo ""
echo "📋 Access Information:"
echo "====================="
echo "🎨 Dashboard URL: http://localhost:3000/d/otel-sli-slo-dashboard"
echo "📊 Prometheus: http://localhost:9090"
echo ""
echo "📈 SLI/SLO Panels:"
echo "   1. Request Rate (Throughput SLI)"
echo "   2. Response Time P95/P99 (Latency SLI)"
echo "   3. Error Rate (Availability SLI)"
echo "   4. Service Availability SLO (99.9% target)"
echo "   5. Circuit Breaker States"
echo "   6. TimeLimiter Calls"
echo "   7. OTel Collector Ingestion Rate"
echo "   8. Resilience4j Resource Availability"
echo "   9. OTel Collector Health"
echo ""
echo "🎯 SLO Targets:"
echo "   - Availability: 99.9% (< 0.1% error rate)"
echo "   - Latency: P95 < 500ms, P99 < 1000ms"
echo "   - Throughput: Monitor baseline and trends"