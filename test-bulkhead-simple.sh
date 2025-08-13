#!/bin/bash

# Simple Bulkhead Test - Focus on available permits metric

SERVICE_URL="http://localhost:8080"

echo "🔧 Simple Bulkhead Test"
echo "======================"

echo ""
echo "📊 Initial available permits:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "🚀 Starting 4 concurrent long-running requests to bhX (max 3 permits)..."

# Start 4 concurrent requests - should see permits drop to 0, then 4th request should fallback
curl -s "$SERVICE_URL/api/a/bulkhead/x" &
sleep 0.5
curl -s "$SERVICE_URL/api/a/bulkhead/x" &  
sleep 0.5
curl -s "$SERVICE_URL/api/a/bulkhead/x" &
sleep 0.5
curl -s "$SERVICE_URL/api/a/bulkhead/x" &

echo ""
echo "⏳ Checking permits after 2 seconds (should show 0 available for bhX):"
sleep 2
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "⏳ Waiting for requests to complete..."
wait

echo ""
echo "📊 Final permits (should be back to max):"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "📊 Call statistics:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_calls"