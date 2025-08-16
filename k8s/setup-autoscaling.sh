#!/bin/bash

# Setup Autoscaling for Kubernetes

NAMESPACE=${1:-resilience4j-local}
ENABLE_VPA=${2:-false}

echo "🔧 Setting up autoscaling for namespace: $NAMESPACE"

# Install metrics server
echo "📊 Installing metrics server..."
kubectl apply -f autoscaling/metrics-server.yaml

# Wait for metrics server to be ready
echo "⏳ Waiting for metrics server..."
kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system

# Install VPA if requested
if [ "$ENABLE_VPA" = "true" ]; then
    echo "📈 Installing Vertical Pod Autoscaler..."
    
    # Clone VPA repository if not exists
    if [ ! -d "autoscaler" ]; then
        git clone https://github.com/kubernetes/autoscaler.git
    fi
    
    # Install VPA
    cd autoscaler/vertical-pod-autoscaler/
    ./hack/vpa-install.sh
    cd ../../
    
    echo "✅ VPA installed"
fi

# Apply HPA
echo "📊 Applying Horizontal Pod Autoscaler..."
kubectl apply -f autoscaling/hpa-service-a.yaml -n $NAMESPACE

# Apply VPA if enabled
if [ "$ENABLE_VPA" = "true" ]; then
    echo "📈 Applying Vertical Pod Autoscaler..."
    kubectl apply -f autoscaling/vpa-service-a.yaml -n $NAMESPACE
fi

echo "✅ Autoscaling setup completed!"
echo "📊 Check HPA status: kubectl get hpa -n $NAMESPACE"
if [ "$ENABLE_VPA" = "true" ]; then
    echo "📈 Check VPA status: kubectl get vpa -n $NAMESPACE"
fi