#!/bin/bash
echo "🔧 Configuring OTel Collector to scrape Prometheus endpoints..."

cd "$(dirname "$0")/../.."

echo
echo "1. Updating OTel Collector config for Prometheus scraping..."
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

echo "✅ Config updated"

echo
echo "2. Enabling Prometheus export in services..."
# Enable Prometheus in service configs
sed -i 's/prometheus:.*enabled: false/prometheus:\n        enabled: true/' ../service-a/src/main/resources/application.yml
sed -i 's/prometheus:.*enabled: false/prometheus:\n        enabled: true/' ../service-b/src/main/resources/application.yml

echo
echo "3. Rebuilding services..."
./build.sh

echo
echo "4. Restarting stack..."
docker compose down
docker compose up -d

echo
echo "5. Waiting for services..."
sleep 30

echo
echo "6. Testing service Prometheus endpoints..."
echo "Service A metrics:"
SERVICE_A_METRICS=$(curl -s http://localhost:8080/actuator/prometheus | wc -l)
echo "Lines: $SERVICE_A_METRICS"

echo "Service B metrics:"
SERVICE_B_METRICS=$(curl -s http://localhost:8081/actuator/prometheus | wc -l)
echo "Lines: $SERVICE_B_METRICS"

echo
echo "7. Generating traffic..."
for i in {1..5}; do
    curl -s http://localhost:8080/api/a/ok > /dev/null
    curl -s http://localhost:8080/api/a/slow?delayMs=500 > /dev/null
done

echo
echo "8. Checking OTel Collector scraping..."
sleep 15

SCRAPED_METRICS=$(curl -s http://localhost:9464/metrics | wc -l)
echo "Port 9464 metrics lines: $SCRAPED_METRICS"

if [ "$SCRAPED_METRICS" -gt 50 ]; then
    echo "✅ OTel Collector scraping working!"
    echo "Sample metrics:"
    curl -s http://localhost:9464/metrics | grep -E "(http_server_requests|resilience4j_)" | head -3
else
    echo "❌ Still no metrics on port 9464"
    echo "Checking OTel Collector logs:"
    docker logs otel-collector --tail 10
fi

echo
echo "🎯 Port 9464 should now have application metrics!"
echo "📊 Grafana data source: http://otel-collector:9464"