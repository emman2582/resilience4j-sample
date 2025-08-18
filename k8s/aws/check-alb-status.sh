#!/bin/bash

# Check ALB and Ingress Status Script

NAMESPACE=${1:-resilience4j-single}

echo "🔍 Checking ALB and Ingress Status for $NAMESPACE..."

echo "📋 Ingress Status:"
kubectl get ingress -n $NAMESPACE

echo ""
echo "📋 ALB Status:"
aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?contains(LoadBalancerName, 'k8s')].[LoadBalancerName,DNSName,State.Code]" --output table

echo ""
echo "📋 Target Groups:"
aws elbv2 describe-target-groups --region us-east-1 --query "TargetGroups[?VpcId=='vpc-0f932972e0f09e0b0'].[TargetGroupName,Port,HealthCheckPath]" --output table

echo ""
echo "📋 Service Endpoints:"
kubectl get endpoints -n $NAMESPACE

echo ""
echo "📋 Pod Status:"
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "🧪 Testing ALB (if active):"
ALB_URL=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -n "$ALB_URL" ]; then
    echo "Testing: http://$ALB_URL/actuator/health"
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "http://$ALB_URL/actuator/health" || echo "ALB not ready yet"
else
    echo "ALB URL not available yet"
fi

echo ""
echo "💡 Use port forwarding as alternative:"
echo "kubectl port-forward svc/service-a 8082:8080 -n $NAMESPACE"
echo "kubectl port-forward svc/grafana 3001:3000 -n $NAMESPACE"