#!/bin/bash

# Prometheus Datasource Setup Script for Grafana

GRAFANA_URL=${1:-http://localhost:3000}
GRAFANA_USER=${2:-admin}
GRAFANA_PASS=${3:-admin}
ENVIRONMENT=${4:-local}

echo "🔗 Setting up Prometheus datasource in Grafana..."
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
    sleep 2
done

# Set Prometheus URL based on environment
if [ "$ENVIRONMENT" = "local" ]; then
    PROMETHEUS_URL="http://prometheus:9090"
elif [ "$ENVIRONMENT" = "aws-multi" ]; then
    PROMETHEUS_URL="http://prometheus.resilience4j-aws-multi:9090"
else
    PROMETHEUS_URL="http://prometheus.resilience4j-aws-single:9090"
fi

echo "📊 Prometheus URL: $PROMETHEUS_URL"

# Check if datasource already exists
existing_ds=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/datasources/name/Prometheus")

if echo "$existing_ds" | grep -q '"id"'; then
    echo "📝 Updating existing Prometheus datasource..."
    ds_id=$(echo "$existing_ds" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    
    update_payload=$(cat << EOF
{
  "id": $ds_id,
  "name": "Prometheus",
  "type": "prometheus",
  "url": "$PROMETHEUS_URL",
  "access": "proxy",
  "isDefault": true,
  "basicAuth": false
}
EOF
)
    
    response=$(curl -s -X PUT \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        -d "$update_payload" \
        "$GRAFANA_URL/api/datasources/$ds_id")
else
    echo "➕ Creating new Prometheus datasource..."
    
    create_payload=$(cat << EOF
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "$PROMETHEUS_URL",
  "access": "proxy",
  "isDefault": true,
  "basicAuth": false
}
EOF
)
    
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        -d "$create_payload" \
        "$GRAFANA_URL/api/datasources")
fi

# Check response
if echo "$response" | grep -q '"id"' || echo "$response" | grep -q "already exists"; then
    if echo "$response" | grep -q "already exists"; then
        echo "✅ Prometheus datasource already exists (skipping creation)"
    else
        echo "✅ Prometheus datasource configured successfully"
    fi
    
    # Test datasource connection
    echo "🧪 Testing datasource connection..."
    test_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        "$GRAFANA_URL/api/datasources/proxy/1/api/v1/query?query=up")
    
    if echo "$test_response" | grep -q '"status":"success"'; then
        echo "✅ Datasource connection test passed"
    else
        echo "⚠️  Datasource connection test failed - Prometheus may not be ready yet"
    fi
else
    echo "❌ Failed to configure Prometheus datasource"
    echo "Response: $response"
    exit 1
fi

echo "🎯 Prometheus datasource setup completed!"