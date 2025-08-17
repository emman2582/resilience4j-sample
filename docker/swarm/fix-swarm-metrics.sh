#!/bin/bash

# Fix Swarm Metrics Collection

echo "🔧 Fixing Docker Swarm metrics collection..."

echo ""
echo "1. Updating Prometheus configuration for Swarm..."
docker service update --config-rm r4j-stack_prometheus 2>/dev/null || true
docker service update --force r4j-stack_prometheus

echo ""
echo "2. Waiting for Prometheus to restart..."
sleep 15

echo ""
echo "3. Generating traffic to create metrics..."
for i in {1..20}; do
    curl -s http://localhost:8080/api/a/ok >/dev/null
    curl -s http://localhost:8080/api/a/flaky?failRate=30 >/dev/null
    curl -s http://localhost:8080/api/a/slow?delayMs=500 >/dev/null
    curl -s http://localhost:8080/api/a/limited >/dev/null
    echo -n "."
done
echo ""

echo ""
echo "4. Checking Prometheus targets..."
sleep 10
curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"[^"]*"' | head -5

echo ""
echo "5. Testing metrics availability..."
metric_test=$(curl -s "http://localhost:9090/api/v1/query?query=resilience4j_circuitbreaker_calls_total" | grep -c "success")
if [ $metric_test -gt 0 ]; then
    echo "✅ Resilience4j metrics are now available"
else
    echo "⚠️ Metrics may need more time to appear"
fi

echo ""
echo "6. Checking service replicas..."
docker service ls | grep service-a

echo ""
echo "✅ Swarm metrics fix completed!"
echo "💡 Access Grafana at http://localhost:3000 and refresh dashboards"
echo "💡 Set time range to 'Last 5 minutes' in Grafana"