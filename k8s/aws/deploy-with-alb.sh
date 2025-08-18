#!/bin/bash

# Integrated ALB + Kubernetes Deployment Script

TYPE=${1:-single}
REGION=${2:-us-east-1}

case $TYPE in
  "single")
    NAMESPACE="resilience4j-single"
    ALB_NAME="resilience4j-alb-single"
    ;;
  "multi")
    NAMESPACE="resilience4j-multi"
    ALB_NAME="resilience4j-alb-multi"
    ;;
  *)
    echo "Usage: $0 [single|multi] [region]"
    exit 1
    ;;
esac

echo "🚀 Deploying Resilience4j $TYPE environment with pre-configured ALB..."

# Step 1: Setup ALB resources
echo "📋 Step 1: Setting up AWS ALB resources..."
./setup-alb-resources.sh $TYPE $REGION

if [ $? -ne 0 ]; then
    echo "❌ Failed to setup ALB resources"
    exit 1
fi

# Load ALB configuration
source "alb-config-$TYPE.env"

echo "📋 Using ALB: $ALB_DNS"

# Step 2: Deploy Kubernetes resources
echo "📋 Step 2: Deploying Kubernetes resources..."
kubectl apply -f ../$TYPE/all-in-one.yaml

# Step 3: Create ingress with pre-configured ALB
echo "📋 Step 3: Creating ingress with existing ALB..."

# Use dedicated ingress file for the environment type
kubectl apply -f "$TYPE-alb-ingress.yaml"

# Step 4: Wait for pods to be ready
echo "📋 Step 4: Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=service-a -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=service-b -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=prometheus -n $NAMESPACE --timeout=300s

# Step 5: Register targets with ALB target groups
echo "📋 Step 5: Registering pod IPs with target groups..."

# Get pod IPs
SERVICE_A_IPS=$(kubectl get pods -l app=service-a -n $NAMESPACE -o jsonpath='{.items[*].status.podIP}')
GRAFANA_IPS=$(kubectl get pods -l app=grafana -n $NAMESPACE -o jsonpath='{.items[*].status.podIP}')

# Register Service A targets
for ip in $SERVICE_A_IPS; do
    aws elbv2 register-targets \
        --target-group-arn $SERVICE_A_TG_ARN \
        --targets Id=$ip,Port=8080 \
        --region $REGION
    echo "✅ Registered Service A: $ip:8080"
done

# Register Grafana targets
for ip in $GRAFANA_IPS; do
    aws elbv2 register-targets \
        --target-group-arn $GRAFANA_TG_ARN \
        --targets Id=$ip,Port=3000 \
        --region $REGION
    echo "✅ Registered Grafana: $ip:3000"
done

# Step 6: Wait for targets to be healthy
echo "📋 Step 6: Waiting for targets to be healthy..."
echo "⏳ This may take 2-3 minutes..."

# Wait for Service A targets
aws elbv2 wait target-in-service --target-group-arn $SERVICE_A_TG_ARN --region $REGION

# Wait for Grafana targets
aws elbv2 wait target-in-service --target-group-arn $GRAFANA_TG_ARN --region $REGION

# Step 7: Test endpoints
echo "📋 Step 7: Testing endpoints..."

echo "🧪 Testing Service A health endpoint..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "http://$ALB_DNS/actuator/health"

echo "🧪 Testing Grafana endpoint..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "http://$ALB_DNS/grafana/api/health"

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Access Points:"
echo "🌐 Service A: http://$ALB_DNS/"
echo "📊 Grafana: http://$ALB_DNS/grafana (admin/admin)"
echo "📈 Prometheus: Use port-forward - kubectl port-forward svc/prometheus 9090:9090 -n $NAMESPACE"
echo ""
echo "🧪 Test Resilience Patterns:"
echo "curl http://$ALB_DNS/api/a/ok"
echo "curl http://$ALB_DNS/api/a/flaky?failRate=60"
echo "curl http://$ALB_DNS/api/a/slow?delayMs=3000"
echo ""
echo "📊 Load Grafana Dashboards:"
echo "cd ../../grafana/scripts && ./load-dashboards-k8s.sh $NAMESPACE $TYPE"
echo ""
echo "🧹 Cleanup:"
echo "./cleanup-alb.sh $TYPE $REGION"