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
    
    # Create dashboard payload without jq
    local temp_payload="/tmp/dashboard_payload_$$.json"
    echo '{' > "$temp_payload"
    echo '  "dashboard":' >> "$temp_payload"
    cat "$dashboard_file" >> "$temp_payload"
    echo ',' >> "$temp_payload"
    echo '  "overwrite": true,' >> "$temp_payload"
    echo '  "inputs": [],' >> "$temp_payload"
    echo '  "folderId": 0' >> "$temp_payload"
    echo '}' >> "$temp_payload"
    
    # Load dashboard
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        -d @"$temp_payload" \
        "$GRAFANA_URL/api/dashboards/db")
    
    # Clean up temp file
    rm -f "$temp_payload"
    
    if echo "$response" | grep -q '"status":"success"'; then
        echo "✅ Dashboard loaded: $dashboard_name"
    else
        echo "❌ Failed to load dashboard: $dashboard_name"
        echo "Response: $response"
    fi
}

# Set up Prometheus data source
echo "🔗 Setting up Prometheus datasource..."
"$(dirname "$0")/setup-prometheus-datasource.sh" "$GRAFANA_URL" "$GRAFANA_USER" "$GRAFANA_PASS" "$ENVIRONMENT"

if [ $? -ne 0 ]; then
    echo "❌ Failed to setup Prometheus datasource"
    exit 1
fi

# Load dashboard files from dashboards directory
cd "$(dirname "$0")/../dashboards"
if [ ! -d "." ]; then
    echo "❌ Dashboards directory not found"
    exit 1
fi

dashboard_count=0
for dashboard in *.json; do
    if [ -f "$dashboard" ]; then
        load_dashboard "$dashboard"
        ((dashboard_count++))
    fi
done

if [ $dashboard_count -eq 0 ]; then
    echo "⚠️  No dashboard files found in dashboards directory"
fi

echo "✅ Dashboard loading completed!"
echo "🌐 Access Grafana at: $GRAFANA_URL"