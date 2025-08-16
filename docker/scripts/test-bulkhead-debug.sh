#!/bin/bash

# Debug Bulkhead Test - Check if bulkhead is working at all

SERVICE_URL="http://localhost:8080"

echo "🔍 Bulkhead Debug Test"
echo "====================="

echo ""
echo "1. Testing single request to see baseline timing..."
time curl -s "$SERVICE_URL/api/a/bulkhead/x" > /dev/null

echo ""
echo "2. Check if bulkhead annotations are working..."
echo "Starting 5 concurrent requests with 10-second delays..."

# Increase delay to 10 seconds to make it very obvious
curl -s "$SERVICE_URL/api/a/bulkhead/x" &
PID1=$!
curl -s "$SERVICE_URL/api/a/bulkhead/x" &
PID2=$!
curl -s "$SERVICE_URL/api/a/bulkhead/x" &
PID3=$!
curl -s "$SERVICE_URL/api/a/bulkhead/x" &
PID4=$!

echo "Started 4 requests, checking metrics immediately..."
sleep 1

echo ""
echo "📊 Metrics after 1 second:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "📊 All bulkhead metrics:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead"

echo ""
echo "⏳ Waiting for requests to complete..."
wait $PID1 $PID2 $PID3 $PID4

echo ""
echo "📊 Final metrics:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_bulkhead_available_concurrent_calls"

echo ""
echo "🔍 Checking application logs for bulkhead activity..."
echo "Look for 'Starting work simulation' messages in service-a logs"