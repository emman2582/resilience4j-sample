#!/bin/bash

# Kubernetes Grafana Dashboard Loader

NAMESPACE=${1:-resilience4j-local}
ENVIRONMENT=${2:-local}

echo "📊 Loading Grafana dashboards in Kubernetes..."
echo "Namespace: $NAMESPACE"
echo "Environment: $ENVIRONMENT"

# Port forward to Grafana
echo "🔗 Setting up port forwarding to Grafana..."
kubectl port-forward svc/grafana 3000:3000 -n $NAMESPACE &
PORT_FORWARD_PID=$!

# Wait for port forward to be ready
sleep 10

# Load dashboards using local script
./load-dashboards.sh http://localhost:3000 admin admin $ENVIRONMENT

# Clean up port forwarding
kill $PORT_FORWARD_PID 2>/dev/null

echo "✅ Kubernetes dashboard loading completed!"