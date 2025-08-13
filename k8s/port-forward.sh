#!/bin/bash

# Port forwarding script with proper pod status checking

echo "🔍 Checking pod status..."
kubectl get pods

echo ""
echo "🔗 Setting up port forwarding..."

# Function to setup port forward with retry
setup_port_forward() {
    local service=$1
    local port=$2
    local pod_name=$(kubectl get pods -l app=$service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        echo "❌ No pod found for service: $service"
        return 1
    fi
    
    local pod_status=$(kubectl get pod $pod_name -o jsonpath='{.status.phase}')
    if [ "$pod_status" != "Running" ]; then
        echo "⚠️  Pod $pod_name is not running (status: $pod_status)"
        return 1
    fi
    
    echo "✅ Setting up port-forward for $service ($pod_name) on port $port"
    kubectl port-forward pod/$pod_name $port:$port &
    sleep 2
}

# Kill existing port-forwards
echo "🧹 Cleaning up existing port-forwards..."
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 2

# Setup port forwards for running pods
setup_port_forward "service-a" "8080"
setup_port_forward "service-b" "8081"
setup_port_forward "prometheus" "9090"
setup_port_forward "grafana" "3000"
setup_port_forward "otel-collector" "9464"

echo ""
echo "🌐 Port forwarding active. Access services at:"
echo "  - Service A: http://localhost:8080"
echo "  - Service B: http://localhost:8081"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3000"
echo "  - OTel Collector Metrics: http://localhost:9464/metrics"
echo ""
echo "🛑 To stop port forwarding: pkill -f 'kubectl port-forward'"