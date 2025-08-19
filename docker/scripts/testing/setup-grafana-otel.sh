#!/bin/bash
echo "🎨 Setting up Grafana with OpenTelemetry Dashboard..."

echo
echo "1. Configuring Grafana data source..."
# Wait for Grafana to be ready
sleep 5

# Create Prometheus data source pointing to OTel collector
curl -X POST \
  http://admin:admin@localhost:3000/api/datasources \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "otel-collector",
    "type": "prometheus",
    "url": "http://otel-collector:9464",
    "access": "proxy",
    "isDefault": true
  }' 2>/dev/null

echo "✅ Data source configured"

echo
echo "2. Importing OpenTelemetry dashboard..."
# Import the OpenTelemetry dashboard
DASHBOARD_JSON=$(cat "$(dirname "$0")/../../dashboards/grafana-dashboard-opentelemetry.json")

curl -X POST \
  http://admin:admin@localhost:3000/api/dashboards/db \
  -H 'Content-Type: application/json' \
  -d "{\"dashboard\": $DASHBOARD_JSON, \"overwrite\": true}" 2>/dev/null

echo "✅ Dashboard imported"

echo
echo "3. Testing dashboard access..."
DASHBOARD_URL="http://localhost:3000/d/otel-e2e-transactions/opentelemetry-end-to-end-transactions"
echo "   Dashboard URL: $DASHBOARD_URL"

echo
echo "4. Generating test data for dashboard..."
echo "   Creating varied traffic patterns..."

# Generate different types of requests for dashboard visualization
for i in {1..20}; do
    curl -s http://localhost:8080/api/a/ok > /dev/null
    curl -s "http://localhost:8080/api/a/slow?delayMs=500" > /dev/null
    
    if [ $((i % 5)) -eq 0 ]; then
        curl -s "http://localhost:8080/api/a/flaky?failRate=70" > /dev/null
    fi
    
    if [ $((i % 3)) -eq 0 ]; then
        curl -s http://localhost:8080/api/a/limited > /dev/null
    fi
    
    sleep 0.5
done

echo "✅ Test data generated"

echo
echo "5. Dashboard verification..."
sleep 10

# Check if metrics are available for the dashboard
METRICS_COUNT=$(curl -s http://localhost:9464/metrics | grep -E "(http_server_requests|resilience4j_|otelcol_)" | wc -l)
echo "   Available metrics: $METRICS_COUNT"

if [ "$METRICS_COUNT" -gt 10 ]; then
    echo "   ✅ Dashboard should display data"
else
    echo "   ⚠️  Limited data available"
fi

echo
echo "🎯 Grafana OpenTelemetry Setup Complete!"
echo ""
echo "📋 Access Information:"
echo "====================="
echo "🎨 Grafana: http://localhost:3000"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "📊 OpenTelemetry Dashboard:"
echo "   $DASHBOARD_URL"
echo ""
echo "🔍 Data Source: otel-collector (http://otel-collector:9464)"
echo ""
echo "📈 Expected Dashboard Panels:"
echo "   - Request Rate by Service"
echo "   - Response Time Distribution"
echo "   - Error Rate by Service"
echo "   - Circuit Breaker States"
echo "   - Active Requests"
echo "   - Trace Export Rate"