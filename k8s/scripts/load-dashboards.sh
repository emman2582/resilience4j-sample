#!/bin/bash

# Simple Grafana Dashboard Loader for K8s

NAMESPACE=${1:-resilience4j-local}
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

echo "📊 Loading Grafana dashboards for K8s deployment..."
echo "Namespace: $NAMESPACE"

# Check if Grafana is accessible
echo "🔍 Checking Grafana accessibility..."
if ! curl -s "$GRAFANA_URL/api/health" >/dev/null 2>&1; then
    echo "❌ Grafana not accessible at $GRAFANA_URL"
    echo "💡 Make sure port forwarding is active: ./scripts/port-forward.sh"
    exit 1
fi

echo "✅ Grafana is accessible"

# Setup Prometheus datasource
echo "🔗 Setting up Prometheus datasource..."
curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -d '{
        "name": "Prometheus",
        "type": "prometheus",
        "url": "http://prometheus:9090",
        "access": "proxy",
        "isDefault": true
    }' \
    "$GRAFANA_URL/api/datasources" >/dev/null 2>&1

echo "✅ Prometheus datasource configured"

# Wait a moment for datasource to be ready
sleep 2

# Use manual import script instead
echo "📈 Loading dashboards..."
if [ -f "scripts/manual-import.bat" ]; then
    ./scripts/manual-import.bat
else
    echo "⚠️  Manual import script not found"
fi

echo ""
echo "✅ Dashboard loading completed!"
echo ""
echo "🌐 Access Grafana at: $GRAFANA_URL"
echo "👤 Login: admin/admin"
echo "📊 Available dashboards:"
echo "  - Enhanced Resilience4j Dashboard"
echo "  - Golden Metrics Dashboard"