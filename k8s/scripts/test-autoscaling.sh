#!/bin/bash

# Test Autoscaling Script

NAMESPACE=${1:-resilience4j-local}

echo "🧪 Testing autoscaling in namespace: $NAMESPACE"

# Generate load to trigger HPA
echo "📈 Generating load to trigger HPA..."
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -n $NAMESPACE -- /bin/sh -c "
while true; do
  wget -q -O- http://service-a:8080/api/a/ok
  sleep 0.1
done"

# Monitor HPA in another terminal
echo "📊 Monitor HPA with: kubectl get hpa -n $NAMESPACE -w"
echo "📊 Monitor pods with: kubectl get pods -n $NAMESPACE -w"