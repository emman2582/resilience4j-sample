#!/bin/bash
echo "🔍 Testing Grafana connection to OpenTelemetry metrics..."

echo
echo "1. Direct OTel collector test..."
echo "Available metrics from OTel collector:"
curl -s http://localhost:9464/metrics | grep -E "(http_server_requests|resilience4j_)" | head -5

echo
echo "2. Testing Grafana API access..."
curl -s http://admin:admin@localhost:3000/api/datasources

echo
echo "3. Testing Prometheus API through Grafana..."
echo "Query: up"
curl -s "http://admin:admin@localhost:3000/api/datasources/proxy/1/api/v1/query?query=up"

echo
echo "4. Testing specific metrics..."
echo "Query: http_server_requests_total"
curl -s "http://admin:admin@localhost:3000/api/datasources/proxy/1/api/v1/query?query=http_server_requests_total"

echo
echo "5. Manual verification steps:"
echo "   1. Open Grafana: http://localhost:3000"
echo "   2. Go to Connections → Data Sources"
echo "   3. Click 'prometheus' data source"
echo "   4. Verify URL: http://otel-collector:9464"
echo "   5. Click 'Save & Test'"

echo
echo "6. If still failing, try localhost URL:"
echo "   Change data source URL to: http://localhost:9464"