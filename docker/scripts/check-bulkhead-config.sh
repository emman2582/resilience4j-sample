#!/bin/bash

# Check if bulkhead configuration is properly loaded

SERVICE_URL="http://localhost:8080"

echo "🔍 Bulkhead Configuration Check"
echo "==============================="

echo ""
echo "1. Check if Resilience4j is configured:"
curl -s $SERVICE_URL/actuator/configprops | grep -i resilience4j | head -5

echo ""
echo "2. Check all available metrics:"
curl -s $SERVICE_URL/actuator/metrics | grep -i bulkhead

echo ""
echo "3. Check specific bulkhead metrics:"
curl -s $SERVICE_URL/actuator/metrics/resilience4j.bulkhead.available.concurrent.calls

echo ""
echo "4. Check Prometheus metrics:"
curl -s $SERVICE_URL/actuator/prometheus | grep bulkhead | head -10

echo ""
echo "5. Test simple endpoint to verify service is working:"
curl -s $SERVICE_URL/api/a/ok