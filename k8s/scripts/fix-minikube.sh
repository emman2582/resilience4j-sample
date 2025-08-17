#!/bin/bash

# Fix Minikube Issues Script

echo "🔧 Fixing Minikube Issues"
echo "========================="

echo ""
echo "1. Checking current minikube status..."
minikube status || echo "Minikube is not running properly"

echo ""
echo "2. Stopping minikube (if running)..."
minikube stop

echo ""
echo "3. Deleting corrupted minikube cluster..."
minikube delete

echo ""
echo "4. Starting fresh minikube cluster..."
minikube start --driver=docker --memory=4096 --cpus=2

echo ""
echo "5. Verifying new cluster..."
minikube status
kubectl get nodes

echo ""
echo "6. Loading Docker images into new cluster..."
if [ -f "../service-a/build/libs/service-a-0.1.0.jar" ] && [ -f "../service-b/build/libs/service-b-0.1.0.jar" ]; then
    echo "Loading service images..."
    minikube image load r4j-sample-service-a:0.1.0
    minikube image load r4j-sample-service-b:0.1.0
    echo "Images loaded successfully!"
else
    echo "⚠️  JAR files not found. Run 'gradle clean build' first."
fi

echo ""
echo "✅ Minikube cluster reset complete!"
echo ""
echo "🚀 Next steps:"
echo "1. Run: ./deploy.sh"
echo "2. Run: ./port-forward.sh"