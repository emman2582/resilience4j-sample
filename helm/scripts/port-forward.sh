#!/bin/bash

# Port Forward Script for Resilience4j Stack
# This script sets up port forwarding for all services

NAMESPACE="r4j-monitoring"

echo "🔗 Setting up port forwarding for Resilience4j Stack..."

# Function to start port forwarding in background
start_port_forward() {
    local service=$1
    local local_port=$2
    local remote_port=$3
    local description=$4
    
    echo "Starting port forward for $description..."
    kubectl port-forward svc/$service $local_port:$remote_port -n $NAMESPACE &
    local pid=$!
    echo "  → $description: http://localhost:$local_port (PID: $pid)"
    echo $pid >> /tmp/r4j-port-forwards.pids
}

# Clean up any existing port forwards
cleanup() {
    echo "🧹 Cleaning up existing port forwards..."
    if [ -f /tmp/r4j-port-forwards.pids ]; then
        while read pid; do
            if kill -0 $pid 2>/dev/null; then
                kill $pid
            fi
        done < /tmp/r4j-port-forwards.pids
        rm /tmp/r4j-port-forwards.pids
    fi
    
    # Kill any kubectl port-forward processes (Linux/Mac only)
    if command -v pkill >/dev/null 2>&1; then
        pkill -f "kubectl port-forward.*$NAMESPACE" || true
    fi
}

# Trap to cleanup on exit
trap cleanup EXIT

# Start port forwarding
echo "" > /tmp/r4j-port-forwards.pids

start_port_forward "service-a" "8080" "8080" "Service A (Main API)"
start_port_forward "service-b" "8081" "8081" "Service B (Downstream API)"
start_port_forward "prometheus" "9090" "9090" "Prometheus (Metrics)"
start_port_forward "grafana" "3000" "3000" "Grafana (Dashboards)"
start_port_forward "otel-collector" "4318" "4318" "OpenTelemetry Collector (OTLP HTTP)"

echo ""
echo "✅ Port forwarding is active!"
echo ""
echo "📋 Available Services:"
echo "====================="
echo "🔧 Service A (Main API):     http://localhost:8080"
echo "🔧 Service B (Downstream):   http://localhost:8081"
echo "📊 Prometheus (Metrics):     http://localhost:9090"
echo "📈 Grafana (Dashboards):     http://localhost:3000"
echo "🔍 OpenTelemetry Collector:  http://localhost:4318"
echo ""
echo "🧪 Test Commands:"
echo "=================="
echo "curl http://localhost:8080/api/a/ok"
echo "curl \"http://localhost:8080/api/a/flaky?failRate=60\""
echo "curl \"http://localhost:8080/api/a/slow?delayMs=2500\""
echo "curl http://localhost:8080/api/a/bulkhead/x"
echo "curl http://localhost:8080/api/a/limited"
echo ""
echo "📊 Monitoring:"
echo "=============="
echo "Prometheus Targets: http://localhost:9090/targets"
echo "Grafana Login: admin/admin"
echo ""
echo "Press Ctrl+C to stop all port forwards..."

# Wait for user to stop
wait