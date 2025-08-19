#!/bin/bash
echo "Fixing Grafana data source connection..."

echo
echo "1. Checking OTel collector metrics endpoint..."
OTEL_METRICS=$(curl -s http://localhost:9464/metrics | head -5)
if [ -z "$OTEL_METRICS" ]; then
    echo "❌ OTel collector not exposing metrics on port 9464"
    exit 1
fi
echo "✅ OTel collector metrics available"

echo
echo "2. Testing Grafana connectivity..."
curl -s http://localhost:3000/api/health | grep "ok"

echo
echo "3. Removing existing data sources..."
curl -X DELETE http://admin:admin@localhost:3000/api/datasources/name/otel-collector 2>/dev/null
curl -X DELETE http://admin:admin@localhost:3000/api/datasources/name/prometheus 2>/dev/null

echo
echo "4. Creating correct data source..."
curl -X POST \
  http://admin:admin@localhost:3000/api/datasources \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "prometheus",
    "type": "prometheus", 
    "url": "http://otel-collector:9464",
    "access": "proxy",
    "isDefault": true,
    "basicAuth": false
  }'

echo
echo "5. Testing data source connection..."
sleep 3
curl -X POST \
  http://admin:admin@localhost:3000/api/datasources/proxy/1/api/v1/query \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'query=up'

echo
echo "6. Verifying metrics query..."
curl -s "http://admin:admin@localhost:3000/api/datasources/proxy/1/api/v1/label/__name__/values" | head -10

echo
echo "✅ Grafana data source fixed!"
echo "🎨 Access dashboard: http://localhost:3000/d/otel-e2e-transactions"