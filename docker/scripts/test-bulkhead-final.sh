#!/bin/bash

# Final Bulkhead Test - Guaranteed to show metrics changes
# Uses smaller limits and longer delays

SERVICE_URL="http://localhost:8080"

echo "🔧 Final Bulkhead Test"
echo "======================"
echo "Configuration: bhX=2 permits, bhY=1 permit"
echo "Delays: bhX=10s, bhY=8s"

echo ""
echo "📊 Initial metrics:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "🚀 Test 1: bhX with 3 concurrent requests (2 permits available)"
echo "Expected: available should drop from 2 to 0, then 3rd request should fallback"

curl -s "$SERVICE_URL/api/a/bulkhead/x" &
sleep 1
curl -s "$SERVICE_URL/api/a/bulkhead/x" &
sleep 1
curl -s "$SERVICE_URL/api/a/bulkhead/x" &

echo ""
echo "📊 Metrics after starting 3 requests to bhX (should show 0 available):"
sleep 2
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "🚀 Test 2: bhY with 2 concurrent requests (1 permit available)"
echo "Expected: available should drop from 1 to 0, then 2nd request should fallback"

curl -s "$SERVICE_URL/api/a/bulkhead/y" &
sleep 1
curl -s "$SERVICE_URL/api/a/bulkhead/y" &

echo ""
echo "📊 Metrics during both tests (should show bhX=0, bhY=0):"
sleep 2
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "📊 Call statistics (should show successful and rejected calls):"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_calls"

echo ""
echo "⏳ Waiting for all requests to complete (up to 15 seconds)..."
wait

echo ""
echo "📊 Final metrics (should be back to bhX=2, bhY=1):"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "✅ Test completed!"
echo ""
echo "🔍 What to look for:"
echo "- bhX should go from 2.0 → 0.0 → 2.0"
echo "- bhY should go from 1.0 → 0.0 → 1.0"
echo "- resilience4j_bulkhead_calls should show rejected calls"