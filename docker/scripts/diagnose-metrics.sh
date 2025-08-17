#!/bin/bash

# Metrics Diagnostic Script

echo "🔍 Diagnosing Grafana Metrics Issue..."

echo ""
echo "📊 1. Checking Service Endpoints"
echo "Service A metrics:"
curl -s http://localhost:8080/actuator/prometheus | head -10
if [ $? -eq 0 ]; then
    echo "✅ Service A metrics accessible"
    echo "Resilience4j metrics count:"
    curl -s http://localhost:8080/actuator/prometheus | grep -c "resilience4j"
else
    echo "❌ Service A metrics not accessible"
fi

echo ""
echo "Service B metrics:"
curl -s http://localhost:8081/actuator/prometheus | head -5
if [ $? -eq 0 ]; then
    echo "✅ Service B metrics accessible"
else
    echo "❌ Service B metrics not accessible"
fi

echo ""
echo "📈 2. Checking Prometheus"
echo "Prometheus targets:"
curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"[^"]*"' | head -5

echo ""
echo "Prometheus query test:"
curl -s "http://localhost:9090/api/v1/query?query=up" | grep -o '"status":"[^"]*"'

echo ""
echo "Available metrics:"
curl -s "http://localhost:9090/api/v1/label/__name__/values" | grep -o 'resilience4j[^"]*' | head -5

echo ""
echo "📊 3. Checking Grafana Datasource"
echo "Grafana health:"
curl -s http://localhost:3000/api/health | grep -o '"database":"[^"]*"'

echo ""
echo "Datasource test:"
curl -s -u admin:admin "http://localhost:3000/api/datasources/proxy/1/api/v1/query?query=up" | grep -o '"status":"[^"]*"'

echo ""
echo "🔧 4. Quick Fixes"
echo "Generate some metrics by calling endpoints:"
echo "curl http://localhost:8080/api/a/ok"
echo "curl http://localhost:8080/api/a/flaky?failRate=50"
echo "curl http://localhost:8080/api/a/slow?delayMs=1000"

echo ""
echo "💡 5. Troubleshooting Steps"
echo "If no metrics:"
echo "1. Restart services: docker compose restart"
echo "2. Check logs: docker compose logs service-a"
echo "3. Verify network: docker network ls"
echo "4. Test endpoints manually"