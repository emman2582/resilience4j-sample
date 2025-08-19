#!/bin/bash
echo "Testing Time Limiter implementation..."

echo
echo "1. Testing fast request (should succeed)..."
curl -s "http://localhost:8080/api/a/slow?delayMs=500"

echo
echo
echo "2. Testing slow request (should trigger TimeLimiter after 2s)..."
curl -s "http://localhost:8080/api/a/slow?delayMs=5000"

echo
echo
echo "3. Checking TimeLimiter metrics..."
curl -s http://localhost:8080/actuator/prometheus | grep "resilience4j_timelimiter"

echo
echo "TimeLimiter test complete!"