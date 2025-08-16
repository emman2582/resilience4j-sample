#!/bin/bash

# Resilience4j Stack Helm Deployment Script
# This script builds images, loads them into Minikube, and deploys the Helm chart

set -e

echo "🚀 Starting Resilience4j Stack deployment..."

# Configuration
CHART_NAME="resilience4j-stack"
NAMESPACE="r4j-monitoring"
RELEASE_NAME="resilience4j-stack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install Helm 3.8+"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker"
        exit 1
    fi
    
    if ! command -v gradle &> /dev/null; then
        print_error "Gradle is not installed. Please install Gradle"
        exit 1
    fi
    
    print_status "All prerequisites are installed"
}

# Build application
build_application() {
    echo "🔨 Building application..."
    cd ..
    gradle clean build
    if [ $? -eq 0 ]; then
        print_status "Application built successfully"
    else
        print_error "Application build failed"
        exit 1
    fi
    cd helm
}

# Build Docker images
build_images() {
    echo "🐳 Building Docker images..."
    cd ..
    
    docker build -t r4j-sample-service-a:0.1.0 service-a/
    if [ $? -eq 0 ]; then
        print_status "Service A image built"
    else
        print_error "Failed to build Service A image"
        exit 1
    fi
    
    docker build -t r4j-sample-service-b:0.1.0 service-b/
    if [ $? -eq 0 ]; then
        print_status "Service B image built"
    else
        print_error "Failed to build Service B image"
        exit 1
    fi
    
    cd helm
}

# Load images into Minikube (if using Minikube)
load_images_minikube() {
    if kubectl config current-context | grep -q minikube; then
        echo "📦 Loading images into Minikube..."
        minikube image load r4j-sample-service-a:0.1.0
        minikube image load r4j-sample-service-b:0.1.0
        print_status "Images loaded into Minikube"
    else
        print_warning "Not using Minikube, skipping image loading"
    fi
}

# Create namespace
create_namespace() {
    echo "📁 Creating namespace..."
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    print_status "Namespace '$NAMESPACE' ready"
}

# Deploy Helm chart
deploy_chart() {
    echo "⚡ Deploying Helm chart..."
    
    # Lint the chart first
    helm lint ./resilience4j-stack
    if [ $? -ne 0 ]; then
        print_error "Helm chart linting failed"
        exit 1
    fi
    
    # Install or upgrade the chart
    helm upgrade --install $RELEASE_NAME ./resilience4j-stack \
        --namespace $NAMESPACE \
        --wait \
        --timeout 300s
    
    if [ $? -eq 0 ]; then
        print_status "Helm chart deployed successfully"
    else
        print_error "Helm chart deployment failed"
        exit 1
    fi
}

# Wait for pods to be ready
wait_for_pods() {
    echo "⏳ Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=$RELEASE_NAME -n $NAMESPACE --timeout=300s
    if [ $? -eq 0 ]; then
        print_status "All pods are ready"
    else
        print_warning "Some pods may not be ready yet"
    fi
}

# Display deployment status
show_status() {
    echo ""
    echo "📊 Deployment Status:"
    echo "===================="
    kubectl get pods -n $NAMESPACE
    echo ""
    kubectl get svc -n $NAMESPACE
    echo ""
    echo "🔗 Access URLs (after port-forwarding):"
    echo "Service A: http://localhost:8080"
    echo "Prometheus: http://localhost:9090"
    echo "Grafana: http://localhost:3000 (admin/admin)"
    echo ""
    echo "📝 Port-forward commands:"
    echo "kubectl port-forward svc/service-a 8080:8080 -n $NAMESPACE"
    echo "kubectl port-forward svc/prometheus 9090:9090 -n $NAMESPACE"
    echo "kubectl port-forward svc/grafana 3000:3000 -n $NAMESPACE"
}

# Main execution
main() {
    check_prerequisites
    build_application
    build_images
    load_images_minikube
    create_namespace
    deploy_chart
    wait_for_pods
    show_status
    
    echo ""
    print_status "Deployment completed successfully! 🎉"
}

# Run main function
main "$@"