#!/bin/bash

# Kubernetes Grafana Dashboard Loader

NAMESPACE=${1:-resilience4j-local}
ENVIRONMENT=${2:-local}

echo "📊 Loading Grafana dashboards in Kubernetes..."
echo "Namespace: $NAMESPACE"
echo "Environment: $ENVIRONMENT"

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
    echo "❌ Namespace $NAMESPACE not found"
    echo "💡 Please deploy the application first: cd ../k8s && ./scripts/deploy.sh"
    exit 1
fi

# Check if Grafana service exists
if ! kubectl get svc/grafana -n $NAMESPACE >/dev/null 2>&1; then
    echo "❌ Grafana service not found in namespace $NAMESPACE"
    echo "💡 Please deploy Grafana first"
    exit 1
fi

# Check if port 3000 is already forwarded
if netstat -an 2>/dev/null | grep -q ":3000 " || ss -tuln 2>/dev/null | grep -q ":3000 "; then
    echo "✅ Port 3000 already in use (likely from existing port-forward)"
    echo "🔗 Using existing Grafana connection..."
    PORT_FORWARD_PID=""
else
    # Port forward to Grafana
    echo "🔗 Setting up port forwarding to Grafana..."
    kubectl port-forward svc/grafana 3000:3000 -n $NAMESPACE >/dev/null 2>&1 &
    PORT_FORWARD_PID=$!
    
    # Wait for port forward to be ready
    sleep 10
fi

# Load dashboards using local script (same directory)
"$(dirname "$0")/load-dashboards.sh" http://localhost:3000 admin admin $ENVIRONMENT

# Clean up port forwarding (only if we started it)
if [ -n "$PORT_FORWARD_PID" ]; then
    kill $PORT_FORWARD_PID 2>/dev/null
    echo "🧹 Cleaned up temporary port-forward"
else
    echo "🔗 Leaving existing port-forward active"
fi

echo "✅ Kubernetes dashboard loading completed!"