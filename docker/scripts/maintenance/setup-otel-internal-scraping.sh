#!/bin/bash
echo "🔧 Setting up OpenTelemetry Internal Metrics Scraping..."

cd "$(dirname "$0")/../.."

echo
echo "1. Updating Prometheus config to scrape OTel internal metrics..."
cat > configs/prometheus.yml << 'EOF'
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'service-a'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['service-a:8080']

  - job_name: 'service-b'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['service-b:8081']

  - job_name: 'otel-collector'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['otel-collector:9464']

  - job_name: 'otel-collector-internal'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['otel-collector:8888']
    scrape_interval: 10s
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'otelcol_.*'
        action: keep
        
  - job_name: 'otel-telemetry'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['otel-collector:8888']
    scrape_interval: 15s
EOF

echo "✅ Prometheus config updated"

echo
echo "2. Restarting Prometheus to apply new config..."
docker compose restart prometheus

echo
echo "3. Waiting for Prometheus to reload..."
sleep 15

echo
echo "4. Testing OTel internal metrics scraping..."
echo "Checking Prometheus targets:"
curl -s http://localhost:9090/api/v1/targets | grep -E "(otel-collector|State)" | head -10

echo
echo "5. Verifying OTel metrics in Prometheus:"
OTEL_METRICS_COUNT=$(curl -s "http://localhost:9090/api/v1/label/__name__/values" | grep -c "otelcol_")
echo "OTel metrics in Prometheus: $OTEL_METRICS_COUNT"

if [ "$OTEL_METRICS_COUNT" -gt 5 ]; then
    echo "✅ OTel internal metrics successfully scraped"
    echo "Sample metrics:"
    curl -s "http://localhost:9090/api/v1/label/__name__/values" | grep -o '"otelcol_[^"]*"' | head -5
else
    echo "❌ OTel internal metrics not found in Prometheus"
fi

echo
echo "6. Testing key OTel metrics queries:"
echo "Process uptime:"
curl -s "http://localhost:9090/api/v1/query?query=otelcol_process_uptime" | grep -o '"value":\[[^]]*\]'

echo
echo "Received spans:"
curl -s "http://localhost:9090/api/v1/query?query=otelcol_receiver_accepted_spans_total" | grep -o '"value":\[[^]]*\]'

echo
echo "🎯 Setup Complete!"
echo "📊 OTel internal metrics now available in:"
echo "   - Prometheus: http://localhost:9090"
echo "   - Direct access: http://localhost:8888/metrics"
echo "   - Container hostname: otel-collector:8888"
echo ""
echo "🔍 Key metrics to monitor:"
echo "   - otelcol_process_uptime"
echo "   - otelcol_receiver_accepted_spans_total"
echo "   - otelcol_receiver_accepted_metric_points_total"
echo "   - otelcol_exporter_sent_spans_total"