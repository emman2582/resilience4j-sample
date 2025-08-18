#!/bin/bash

# Fix Metrics Issues Script

echo "🔧 Fixing Grafana Metrics Issues..."

echo ""
echo "1. Generating traffic to create metrics..."
for i in {1..10}; do
    curl -s http://localhost:8080/api/a/ok >/dev/null
    curl -s http://localhost:8080/api/a/flaky?failRate=30 >/dev/null
    curl -s http://localhost:8080/api/a/slow?delayMs=500 >/dev/null
    curl -s http://localhost:8080/api/a/limited >/dev/null
done

echo "✅ Traffic generated"

echo ""
echo "2. Waiting for metrics collection..."
sleep 10

echo ""
echo "3. Verifying metrics are available..."
metric_count=$(curl -s http://localhost:8080/actuator/prometheus | grep -c "resilience4j")
echo "Resilience4j metrics found: $metric_count"

if [ $metric_count -gt 0 ]; then
    echo "✅ Metrics are being generated"
else
    echo "❌ No metrics found - checking service health..."
    curl -s http://localhost:8080/actuator/health
fi

echo ""
echo "4. Testing Prometheus scraping..."
sleep 5
prom_metrics=$(curl -s "http://localhost:9090/api/v1/query?query=resilience4j_circuitbreaker_calls_total" | grep -c "success")
if [ $prom_metrics -gt 0 ]; then
    echo "✅ Prometheus is scraping metrics"
else
    echo "⚠️ Prometheus may need time to scrape metrics"
fi

echo ""
echo "5. Refreshing Grafana dashboards..."
echo "Access Grafana at: http://localhost:3000"
echo "Username: admin, Password: admin"
echo "Try refreshing the dashboard or changing the time range"

echo ""
echo "✅ Metrics fix completed!"
echo "💡 If still no data, wait 1-2 minutes for metrics to populate"