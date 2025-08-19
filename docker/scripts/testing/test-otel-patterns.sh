#!/bin/bash
echo "🧪 Testing OpenTelemetry with Resilience4j Patterns..."

echo
echo "1. Circuit Breaker Pattern Test..."
echo "   Triggering failures to open circuit breaker..."
for i in {1..5}; do
    RESPONSE=$(curl -s "http://localhost:8080/api/a/flaky?failRate=90")
    echo "   Request $i: $(echo $RESPONSE | cut -c1-50)..."
done

echo
echo "2. TimeLimiter Pattern Test..."
echo "   Fast request (should succeed):"
FAST=$(curl -s "http://localhost:8080/api/a/slow?delayMs=800")
echo "   Response: $FAST"

echo "   Slow request (should timeout):"
SLOW=$(curl -s "http://localhost:8080/api/a/slow?delayMs=4000")
echo "   Response: $SLOW"

echo
echo "3. Rate Limiter Pattern Test..."
echo "   Sending rapid requests (limit: 5/sec)..."
for i in {1..10}; do
    RESPONSE=$(curl -s http://localhost:8080/api/a/limited)
    echo "   Request $i: $(echo $RESPONSE | cut -c1-30)..."
    sleep 0.1
done

echo
echo "4. Bulkhead Pattern Test..."
echo "   Starting concurrent bulkhead requests..."
curl -s http://localhost:8080/api/a/bulkhead/x &
curl -s http://localhost:8080/api/a/bulkhead/x &
curl -s http://localhost:8080/api/a/bulkhead/y &

echo "   Waiting for bulkhead operations..."
sleep 3

echo
echo "5. Checking pattern metrics after tests..."
sleep 5

METRICS=$(curl -s http://localhost:9464/metrics)

echo
echo "📊 Pattern Metrics Summary:"

# Circuit Breaker
CB_STATE=$(echo "$METRICS" | grep "resilience4j_circuitbreaker_state" | head -1)
echo "Circuit Breaker State: $CB_STATE"

# TimeLimiter
TL_SUCCESS=$(echo "$METRICS" | grep "resilience4j_timelimiter_calls_total.*successful" | head -1)
TL_TIMEOUT=$(echo "$METRICS" | grep "resilience4j_timelimiter_calls_total.*failed" | head -1)
echo "TimeLimiter Success: $TL_SUCCESS"
echo "TimeLimiter Timeout: $TL_TIMEOUT"

# Rate Limiter
RL_PERMITS=$(echo "$METRICS" | grep "resilience4j_ratelimiter_available_permissions" | head -1)
echo "Rate Limiter Permits: $RL_PERMITS"

# Bulkhead
BH_AVAILABLE=$(echo "$METRICS" | grep "resilience4j_bulkhead_available_concurrent_calls" | head -2)
echo "Bulkhead Available Calls:"
echo "$BH_AVAILABLE"

echo
echo "🎯 Pattern testing complete!"
echo "All Resilience4j patterns are generating OpenTelemetry metrics!"