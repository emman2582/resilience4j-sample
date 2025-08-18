#!/bin/bash

# Comprehensive Bulkhead Test
# Tests bulkhead isolation with different permit configurations

SERVICE_URL="http://localhost:8080"

echo "🔧 Comprehensive Bulkhead Test"
echo "=============================="
echo "Configuration: bhX=3 permits, bhY=2 permits"
echo ""

# Function to get bulkhead metrics
get_bulkhead_metrics() {
    echo "📊 Current bulkhead metrics:"
    curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"
    echo ""
}

# Function to get call statistics
get_call_stats() {
    echo "📊 Call statistics:"
    curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_calls"
    echo ""
}

echo "1. Initial state check"
echo "====================="
get_bulkhead_metrics

echo "2. Testing bhX (3 permits) with 4 concurrent requests"
echo "===================================================="
echo "Expected: 3 requests should proceed, 1 should fallback"
echo ""

# Start 4 concurrent requests to bhX
curl -s "$SERVICE_URL/api/a/bulkhead/x" &
sleep 0.5
curl -s "$SERVICE_URL/api/a/bulkhead/x" &
sleep 0.5
curl -s "$SERVICE_URL/api/a/bulkhead/x" &
sleep 0.5
curl -s "$SERVICE_URL/api/a/bulkhead/x" &

echo "⏳ Checking metrics after 2 seconds (bhX should show 0 available):"
sleep 2
get_bulkhead_metrics

echo "3. Testing bhY (2 permits) with 3 concurrent requests"
echo "===================================================="
echo "Expected: 2 requests should proceed, 1 should fallback"
echo ""

# Start 3 concurrent requests to bhY
curl -s "$SERVICE_URL/api/a/bulkhead/y" &
sleep 0.5
curl -s "$SERVICE_URL/api/a/bulkhead/y" &
sleep 0.5
curl -s "$SERVICE_URL/api/a/bulkhead/y" &

echo "⏳ Checking metrics during both tests (both should show 0 available):"
sleep 2
get_bulkhead_metrics

echo "4. Waiting for all requests to complete..."
echo "=========================================="
wait

echo "5. Final state check"
echo "===================="
get_bulkhead_metrics
get_call_stats

echo "✅ Test completed!"
echo ""
echo "🔍 What to look for:"
echo "- bhX should go from 3.0 → 0.0 → 3.0"
echo "- bhY should go from 2.0 → 0.0 → 2.0"
echo "- resilience4j_bulkhead_calls should show both successful and rejected calls"