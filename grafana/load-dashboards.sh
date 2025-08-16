#!/bin/bash

# Grafana Dashboard Loader Script

GRAFANA_URL=${1:-http://localhost:3000}
GRAFANA_USER=${2:-admin}
GRAFANA_PASS=${3:-admin}
ENVIRONMENT=${4:-local}

echo "📊 Loading Grafana dashboards..."
echo "URL: $GRAFANA_URL"
echo "Environment: $ENVIRONMENT"

# Wait for Grafana to be ready
echo "⏳ Waiting for Grafana to be ready..."
for i in {1..30}; do
    if curl -s "$GRAFANA_URL/api/health" >/dev/null 2>&1; then
        echo "✅ Grafana is ready"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 5
done

# Function to load dashboard
load_dashboard() {
    local dashboard_file=$1
    local dashboard_name=$(basename "$dashboard_file" .json)
    
    echo "📈 Loading dashboard: $dashboard_name"
    
    # Create dashboard payload
    local payload=$(jq -n --argjson dashboard "$(cat "$dashboard_file")" '{
        dashboard: $dashboard,
        overwrite: true,
        inputs: [],
        folderId: 0
    }')
    
    # Load dashboard
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        -d "$payload" \
        "$GRAFANA_URL/api/dashboards/db")
    
    if echo "$response" | jq -e '.status == "success"' >/dev/null 2>&1; then
        echo "✅ Dashboard loaded: $dashboard_name"
    else
        echo "❌ Failed to load dashboard: $dashboard_name"
        echo "Response: $response"
    fi
}

# Set up Prometheus data source
echo "🔗 Setting up Prometheus data source..."
if [ "$ENVIRONMENT" = "local" ]; then
    PROMETHEUS_URL="http://prometheus:9090"
else
    PROMETHEUS_URL="http://prometheus.resilience4j-aws-single:9090"
fi

datasource_payload=$(cat << EOF
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "$PROMETHEUS_URL",
  "access": "proxy",
  "isDefault": true
}
EOF
)

curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -d "$datasource_payload" \
    "$GRAFANA_URL/api/datasources" >/dev/null

# Load all dashboard files
cd "$(dirname "$0")"
for dashboard in *.json; do
    if [ -f "$dashboard" ]; then
        load_dashboard "$dashboard"
    fi
done

echo "✅ Dashboard loading completed!"
echo "🌐 Access Grafana at: $GRAFANA_URL"