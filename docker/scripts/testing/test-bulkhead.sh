#!/bin/bash

# Bulkhead Testing Script
# This script generates concurrent requests to test bulkhead behavior

echo "🔧 Bulkhead Testing Script"
echo "=========================="

SERVICE_URL="http://localhost:8080"

echo ""
echo "📊 Current Bulkhead Metrics (before load):"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "🚀 Starting concurrent requests to bulkhead/x (3 permits)..."
echo "This will create contention and make metrics visible"

# Generate 6 concurrent requests to bhX (which has only 3 permits)
for i in {1..6}; do
    echo "Starting request $i to bulkhead/x..."
    curl -s "$SERVICE_URL/api/a/bulkhead/x" > /dev/null &
done

echo ""
echo "⏳ Waiting 3 seconds for some requests to start..."
sleep 3

echo ""
echo "📊 Bulkhead Metrics (during load):"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "🚀 Starting concurrent requests to bulkhead/y (2 permits)..."

# Generate 4 concurrent requests to bhY (which has only 2 permits)  
for i in {1..4}; do
    echo "Starting request $i to bulkhead/y..."
    curl -s "$SERVICE_URL/api/a/bulkhead/y" > /dev/null &
done

echo ""
echo "⏳ Waiting 2 seconds..."
sleep 2

echo ""
echo "📊 All Bulkhead Metrics (during mixed load):"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "⏳ Waiting for all requests to complete..."
wait

echo ""
echo "📊 Final Bulkhead Metrics (after load):"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"
echo ""
echo "📊 Bulkhead Call Metrics:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_calls"

echo ""
echo "✅ Test completed!"
echo ""
echo "🔍 Available Bulkhead Metrics:"
echo "- resilience4j_bulkhead_available_concurrent_calls: Available permits"
echo "- resilience4j_bulkhead_max_allowed_concurrent_calls: Maximum permits"
echo ""
echo "📈 To see metrics in Grafana:"
echo "1. Go to http://localhost:3000"
echo "2. Use query: resilience4j_bulkhead_available_concurrent_calls"
echo "3. Use query: resilience4j_bulkhead_max_allowed_concurrent_calls - resilience4j_bulkhead_available_concurrent_calls"