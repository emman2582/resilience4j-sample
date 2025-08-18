#!/bin/bash

# Port Forward Script with Conflict Resolution

NAMESPACE=${1:-resilience4j-local}

echo "🔗 Setting up port forwarding for $NAMESPACE..."

# Kill existing port forwards
echo "🧹 Cleaning up existing port forwards..."
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 2

# Check if pods are ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=service-a -n $NAMESPACE --timeout=60s
kubectl wait --for=condition=ready pod -l app=grafana -n $NAMESPACE --timeout=60s
kubectl wait --for=condition=ready pod -l app=prometheus -n $NAMESPACE --timeout=60s

# Function to find available port
find_available_port() {
    local base_port=$1
    local port=$base_port
    while netstat -an 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; do
        port=$((port + 1))
    done
    echo $port
}

# Find available ports
SERVICE_A_PORT=$(find_available_port 8080)
GRAFANA_PORT=$(find_available_port 3000)
PROMETHEUS_PORT=$(find_available_port 9090)

echo "📋 Using ports:"
echo "  Service A: $SERVICE_A_PORT"
echo "  Grafana: $GRAFANA_PORT"
echo "  Prometheus: $PROMETHEUS_PORT"

# Start port forwards in background
echo "🔗 Starting port forwards..."

kubectl port-forward svc/service-a $SERVICE_A_PORT:8080 -n $NAMESPACE > /dev/null 2>&1 &
SERVICE_A_PID=$!

kubectl port-forward svc/grafana $GRAFANA_PORT:3000 -n $NAMESPACE > /dev/null 2>&1 &
GRAFANA_PID=$!

kubectl port-forward svc/prometheus $PROMETHEUS_PORT:9090 -n $NAMESPACE > /dev/null 2>&1 &
PROMETHEUS_PID=$!

# Wait for port forwards to be ready
sleep 5

# Test connections
echo "🧪 Testing connections..."
if curl -s http://localhost:$SERVICE_A_PORT/actuator/health > /dev/null; then
    echo "✅ Service A: http://localhost:$SERVICE_A_PORT"
else
    echo "❌ Service A connection failed"
fi

if curl -s http://localhost:$GRAFANA_PORT/api/health > /dev/null; then
    echo "✅ Grafana: http://localhost:$GRAFANA_PORT (admin/admin)"
else
    echo "❌ Grafana connection failed"
fi

if curl -s http://localhost:$PROMETHEUS_PORT/-/healthy > /dev/null; then
    echo "✅ Prometheus: http://localhost:$PROMETHEUS_PORT"
else
    echo "❌ Prometheus connection failed"
fi

echo ""
echo "🎯 Access Points:"
echo "  Service A: http://localhost:$SERVICE_A_PORT"
echo "  Grafana: http://localhost:$GRAFANA_PORT (admin/admin)"
echo "  Prometheus: http://localhost:$PROMETHEUS_PORT"
echo ""
echo "🛑 To stop port forwarding:"
echo "  kill $SERVICE_A_PID $GRAFANA_PID $PROMETHEUS_PID"
echo "  or run: pkill -f 'kubectl port-forward'"

# Save PIDs for cleanup
echo "$SERVICE_A_PID $GRAFANA_PID $PROMETHEUS_PID" > /tmp/k8s-port-forward-pids.txt