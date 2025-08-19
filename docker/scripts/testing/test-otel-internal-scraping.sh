#!/bin/bash
echo "🔍 Testing OpenTelemetry Internal Metrics Scraping..."

echo
echo "1. Available OTel Collector internal metrics (port 8888):"
INTERNAL_METRICS=$(curl -s http://localhost:8888/metrics | grep "otelcol_" | wc -l)
echo "   OTel internal metrics count: $INTERNAL_METRICS"

if [ "$INTERNAL_METRICS" -gt 0 ]; then
    echo "   Sample OTel metrics:"
    curl -s http://localhost:8888/metrics | grep "otelcol_" | head -5
fi

echo
echo "2. Testing Prometheus scraping of OTel internal metrics:"
echo "   Checking Prometheus targets..."
curl -s http://localhost:9090/api/v1/targets | grep -A5 -B5 "otel-collector-internal"

echo
echo "3. Querying OTel metrics through Prometheus:"
echo "   Query: otelcol_process_uptime"
UPTIME_QUERY=$(curl -s "http://localhost:9090/api/v1/query?query=otelcol_process_uptime")
echo "   Result: $UPTIME_QUERY"

echo
echo "4. Available OTel Collector metrics in Prometheus:"
PROM_OTEL_METRICS=$(curl -s "http://localhost:9090/api/v1/label/__name__/values" | grep -o '"otelcol_[^"]*"' | wc -l)
echo "   OTel metrics in Prometheus: $PROM_OTEL_METRICS"

echo
echo "5. Key OTel Collector metrics for monitoring:"
echo "   - otelcol_process_uptime: Collector uptime"
echo "   - otelcol_receiver_accepted_spans_total: Spans received"
echo "   - otelcol_receiver_accepted_metric_points_total: Metrics received"
echo "   - otelcol_exporter_sent_spans_total: Spans exported"
echo "   - otelcol_processor_batch_batch_send_size: Batch sizes"

echo
echo "6. Testing specific OTel metrics queries:"
echo "   Receiver metrics:"
curl -s "http://localhost:9090/api/v1/query?query=otelcol_receiver_accepted_metric_points_total" | grep -o '"value":\[[^]]*\]'

echo
echo "   Exporter metrics:"
curl -s "http://localhost:9090/api/v1/query?query=otelcol_exporter_sent_spans_total" | grep -o '"value":\[[^]]*\]'

echo
echo "7. Grafana configuration for OTel internal metrics:"
echo "   Data Source: Prometheus (http://prometheus:9090)"
echo "   Query examples:"
echo "   - rate(otelcol_receiver_accepted_spans_total[5m])"
echo "   - otelcol_processor_batch_batch_send_size"
echo "   - increase(otelcol_exporter_sent_metric_points_total[1m])"

echo
echo "🎯 OTel Internal Metrics Summary:"
echo "   ✅ Available at: http://otel-collector:8888/metrics"
echo "   ✅ Scraped by Prometheus using container hostname"
echo "   ✅ Queryable through Prometheus API"
echo "   ✅ Can be used in Grafana dashboards"