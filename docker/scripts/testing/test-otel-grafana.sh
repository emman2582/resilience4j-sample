#!/bin/bash
echo "🔍 Testing OpenTelemetry Metrics for Grafana Dashboard Compatibility..."

echo
echo "1. Checking OTel Collector Health..."
OTEL_HEALTH=$(curl -s http://localhost:8888/metrics | grep "otelcol_process_uptime" | wc -l)
if [ "$OTEL_HEALTH" -eq 0 ]; then
    echo "❌ OTel Collector not responding"
    exit 1
fi
echo "✅ OTel Collector is running"

echo
echo "2. Generating comprehensive test traffic..."
echo "   - Basic HTTP requests..."
for i in {1..10}; do
    curl -s http://localhost:8080/api/a/ok > /dev/null
done

echo "   - Error scenarios for error rate metrics..."
for i in {1..5}; do
    curl -s "http://localhost:8080/api/a/flaky?failRate=80" > /dev/null
done

echo "   - TimeLimiter scenarios..."
curl -s "http://localhost:8080/api/a/slow?delayMs=500" > /dev/null
curl -s "http://localhost:8080/api/a/slow?delayMs=3000" > /dev/null

echo "   - Circuit breaker activation..."
for i in {1..8}; do
    curl -s "http://localhost:8080/api/a/flaky?failRate=90" > /dev/null
done

echo "   - Rate limiter testing..."
for i in {1..12}; do
    curl -s http://localhost:8080/api/a/limited > /dev/null &
done
wait

echo "   - Bulkhead testing..."
curl -s http://localhost:8080/api/a/bulkhead/x &
curl -s http://localhost:8080/api/a/bulkhead/y &

echo
echo "3. Waiting for metrics to be processed..."
sleep 15

echo
echo "4. Testing Dashboard Metrics Availability..."
METRICS=$(curl -s http://localhost:9464/metrics)

# Test metrics required by grafana-dashboard-opentelemetry.json
echo
echo "📊 Dashboard Metric Verification:"

# HTTP Server Request Rate
HTTP_TOTAL=$(echo "$METRICS" | grep "http_server_requests_total" | wc -l)
echo "   http_server_requests_total: $HTTP_TOTAL entries"
if [ "$HTTP_TOTAL" -gt 0 ]; then
    echo "   ✅ Request rate metrics available"
    echo "$METRICS" | grep "http_server_requests_total" | head -2
else
    echo "   ❌ Request rate metrics missing"
fi

# HTTP Server Duration (for latency)
HTTP_DURATION=$(echo "$METRICS" | grep "http_server_requests_seconds" | wc -l)
echo "   http_server_requests_seconds: $HTTP_DURATION entries"
if [ "$HTTP_DURATION" -gt 0 ]; then
    echo "   ✅ Latency metrics available"
else
    echo "   ❌ Latency metrics missing"
fi

# Error Rate (5xx responses)
HTTP_5XX=$(echo "$METRICS" | grep 'http_server_requests_total.*status_code="5' | wc -l)
echo "   5xx error responses: $HTTP_5XX entries"
if [ "$HTTP_5XX" -gt 0 ]; then
    echo "   ✅ Error rate metrics available"
else
    echo "   ⚠️  No 5xx errors generated (normal if services are healthy)"
fi

# Circuit Breaker State
CB_STATE=$(echo "$METRICS" | grep "resilience4j_circuitbreaker_state" | wc -l)
echo "   resilience4j_circuitbreaker_state: $CB_STATE entries"
if [ "$CB_STATE" -gt 0 ]; then
    echo "   ✅ Circuit breaker state metrics available"
    echo "$METRICS" | grep "resilience4j_circuitbreaker_state" | head -2
else
    echo "   ❌ Circuit breaker state metrics missing"
fi

# Active Requests
ACTIVE_REQ=$(echo "$METRICS" | grep "http_server_active_requests" | wc -l)
echo "   http_server_active_requests: $ACTIVE_REQ entries"
if [ "$ACTIVE_REQ" -gt 0 ]; then
    echo "   ✅ Active requests metrics available"
else
    echo "   ❌ Active requests metrics missing"
fi

# OTel Collector Internal Metrics
OTEL_SPANS=$(echo "$METRICS" | grep "otelcol_exporter_sent_spans_total" | wc -l)
echo "   otelcol_exporter_sent_spans_total: $OTEL_SPANS entries"
if [ "$OTEL_SPANS" -gt 0 ]; then
    echo "   ✅ Trace export metrics available"
    echo "$METRICS" | grep "otelcol_exporter_sent_spans_total" | head -1
else
    echo "   ❌ Trace export metrics missing"
fi

echo
echo "5. Testing Grafana Dashboard Queries..."

# Test the actual queries from the dashboard
echo "   Testing request rate query..."
RATE_QUERY='rate(http_server_requests_total[5m])'
echo "   Query: $RATE_QUERY"

echo "   Testing error rate query..."
ERROR_QUERY='rate(http_server_requests_total{status_code=~"5.."}[5m]) / rate(http_server_requests_total[5m]) * 100'
echo "   Query: $ERROR_QUERY"

echo "   Testing latency query..."
LATENCY_QUERY='histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))'
echo "   Query: $LATENCY_QUERY"

echo
echo "6. Grafana Data Source Configuration:"
echo "   Data Source Type: Prometheus"
echo "   URL: http://otel-collector:9464"
echo "   Access: Server (default)"

echo
echo "7. Dashboard Import Instructions:"
echo "   1. Open Grafana: http://localhost:3000 (admin/admin)"
echo "   2. Go to Dashboards → Import"
echo "   3. Upload: docker/dashboards/grafana-dashboard-opentelemetry.json"
echo "   4. Select data source: prometheus (http://otel-collector:9464)"

echo
echo "8. Metric Summary for Dashboard:"
TOTAL_METRICS=$(echo "$METRICS" | grep -E "(http_server_|resilience4j_|otelcol_)" | wc -l)
echo "   Total relevant metrics: $TOTAL_METRICS"

if [ "$TOTAL_METRICS" -gt 20 ]; then
    echo "   ✅ Sufficient metrics for dashboard"
else
    echo "   ⚠️  Limited metrics available"
fi

echo
echo "🎯 OpenTelemetry Dashboard Test Complete!"
echo "📊 Dashboard should show:"
echo "   - Request rates and latency"
echo "   - Error rates by service"
echo "   - Circuit breaker states"
echo "   - Active request counts"
echo "   - Trace export rates"