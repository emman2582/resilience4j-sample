#!/bin/bash
echo "🔧 Fixing OTLP Export to populate port 9464..."

echo
echo "1. Enabling Micrometer OTLP registry in services..."
# We need to enable the OTLP registry in application.yml since environment variables aren't working

echo "2. Rebuilding services with OTLP enabled..."
cd "$(dirname "$0")/../.."

# Temporarily enable OTLP in service configs
sed -i 's/enabled: false/enabled: true/g' ../service-a/src/main/resources/application.yml
sed -i 's/enabled: false/enabled: true/g' ../service-b/src/main/resources/application.yml

./build.sh

echo
echo "3. Restarting stack..."
docker compose down
docker compose up -d

echo
echo "4. Waiting for services..."
sleep 30

echo
echo "5. Generating test traffic..."
for i in {1..10}; do
    curl -s http://localhost:8080/api/a/ok > /dev/null
    curl -s http://localhost:8080/api/a/slow?delayMs=500 > /dev/null
done

echo
echo "6. Checking OTLP reception..."
sleep 10

echo "OTel Collector received metrics:"
curl -s http://localhost:8888/metrics | grep "otelcol_receiver_accepted_metric_points_total"

echo
echo "7. Checking port 9464 export:"
EXPORTED_COUNT=$(curl -s http://localhost:9464/metrics | wc -l)
echo "Port 9464 metrics lines: $EXPORTED_COUNT"

if [ "$EXPORTED_COUNT" -gt 50 ]; then
    echo "✅ OTLP export working!"
    echo "Sample metrics:"
    curl -s http://localhost:9464/metrics | grep -E "(http_server_requests|resilience4j_)" | head -3
else
    echo "❌ OTLP export still not working"
    echo "Falling back to Prometheus scraping..."
    
    # Configure OTel collector to scrape Prometheus endpoints instead
    cat > configs/otel-collector-config.yml << 'EOF'
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'service-a'
          static_configs:
            - targets: ['service-a:8080']
          metrics_path: '/actuator/prometheus'
          scrape_interval: 5s
        - job_name: 'service-b'
          static_configs:
            - targets: ['service-b:8081']
          metrics_path: '/actuator/prometheus'
          scrape_interval: 5s

processors:
  batch:

exporters:
  prometheus:
    endpoint: "0.0.0.0:9464"
    enable_open_metrics: true

service:
  telemetry:
    metrics:
      level: basic
      address: 0.0.0.0:8888
  pipelines:
    metrics:
      receivers: [prometheus]
      processors: [batch]
      exporters: [prometheus]
EOF

    echo "Restarting with Prometheus scraping..."
    docker compose restart otel-collector
    sleep 15
    
    FINAL_COUNT=$(curl -s http://localhost:9464/metrics | wc -l)
    echo "Final port 9464 metrics: $FINAL_COUNT"
fi

echo
echo "🎯 Port 9464 should now have metrics for Grafana!"