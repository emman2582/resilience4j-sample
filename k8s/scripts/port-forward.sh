#!/bin/bash

# Port forwarding script with proper pod status checking

NAMESPACE="resilience4j-local"
FOREGROUND_MODE=${1:-false}

# Check if ports are available
check_port_available() {
    local port=$1
    if netstat -an 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        return 1
    fi
    return 0
}

# Handle force cleanup option
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    echo "💪 Force cleaning all port forwards and processes..."
    pkill -9 -f "kubectl port-forward" 2>/dev/null || true
    
    # Kill processes on target ports
    for port in 8080 8081 9090 3000 9464; do
        if command -v lsof >/dev/null 2>&1; then
            lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null || true
        fi
    done
    
    sleep 3
    echo "✅ Force cleanup completed"
fi

echo "🔍 Checking pod status in namespace: $NAMESPACE..."
kubectl get pods -n $NAMESPACE

echo ""
echo "🔗 Setting up port forwarding..."

# Function to setup port forward with retry
setup_port_forward() {
    local service=$1
    local port=$2
    local pod_name=$(kubectl get pods -l app=$service -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        echo "❌ No pod found for service: $service"
        return 1
    fi
    
    local pod_status=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null)
    if [ "$pod_status" != "Running" ]; then
        echo "⚠️  Pod $pod_name is not running (status: $pod_status)"
        return 1
    fi
    
    # Check if port is available
    if ! check_port_available $port; then
        echo "❌ Port $port is in use. Skipping $service"
        return 1
    fi
    
    echo "✅ Setting up port-forward for $service ($pod_name) on port $port"
    kubectl port-forward pod/$pod_name $port:$port -n $NAMESPACE >/dev/null 2>&1 &
    sleep 2
    
    # Verify port-forward started successfully
    if check_port_available $port; then
        echo "❌ Failed to start port-forward for $service on port $port"
        return 1
    else
        echo "✅ Port-forward active for $service on port $port"
    fi
}

# Kill existing port-forwards
echo "🧹 Cleaning up existing port-forwards..."
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 2

# Force kill any remaining processes
pkill -9 -f "kubectl port-forward" 2>/dev/null || true
sleep 3

# Kill any processes using our target ports
echo "🧹 Checking for processes using target ports..."
for port in 8080 8081 9090 3000 9464; do
    if command -v lsof >/dev/null 2>&1; then
        # Unix/Linux/Mac
        lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null || true
    elif command -v netstat >/dev/null 2>&1; then
        # Windows
        PID=$(netstat -ano | findstr :$port | awk '{print $5}' | head -1)
        if [ -n "$PID" ] && [ "$PID" != "0" ]; then
            taskkill /PID $PID /F 2>/dev/null || true
        fi
    fi
done
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

if [ "$FOREGROUND_MODE" = "foreground" ]; then
    echo "🛑 To stop port forwarding: pkill -f 'kubectl port-forward'"
    echo "ℹ️  Press Ctrl+C to stop and return to terminal"
    
    # Keep script running in foreground
    echo ""
    echo "Port forwarding active. Press Ctrl+C to stop..."
    trap 'echo "\n🛑 Stopping port forwarding..."; pkill -f "kubectl port-forward"; exit 0' INT
    
    # Wait indefinitely
    while true; do
        sleep 10
    done
else
    # Default: Run as daemon (background)
    echo "🔙 Port forwarding running as daemon"
    echo "🛑 To stop: ./scripts/stop-port-forward.sh"
    echo "🔍 To check status: ps aux | grep 'kubectl port-forward'"
    echo "ℹ️  To run in foreground: ./scripts/port-forward.sh foreground"
    
    # Create PID file for easier management
    echo $$ > /tmp/port-forward-daemon.pid
    echo "📄 Daemon PID: $$ (saved to /tmp/port-forward-daemon.pid)"
fi