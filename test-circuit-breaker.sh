#!/bin/bash

# Circuit Breaker Testing Script

SERVICE_URL="http://localhost:8080"

echo "🔧 Circuit Breaker Test"
echo "======================="

echo ""
echo "📊 Initial circuit breaker state:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_circuitbreaker_state"

echo ""
echo "🧪 Testing Service B directly with high fail rate:"
for i in {1..5}; do
    echo "Direct call $i to Service B:"
    curl -s "http://localhost:8081/api/b/flaky?failRate=80"
    echo ""
done

echo ""
echo "🚀 Testing through Service A with high fail rate (should trigger circuit breaker):"
echo "Making 10 requests with 80% failure rate..."

for i in {1..10}; do
    echo "Request $i:"
    response=$(curl -s "http://localhost:8080/api/a/flaky?failRate=80")
    echo "$response"
    sleep 1
done

echo ""
echo "📊 Circuit breaker state after load:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_circuitbreaker_state"

echo ""
echo "📊 Circuit breaker failure rate:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_circuitbreaker_failure_rate"

echo ""
echo "📊 Circuit breaker call counts:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_circuitbreaker_calls"

echo ""
echo "🔍 Testing if circuit breaker is open (should return fallback):"
for i in {1..3}; do
    echo "Test call $i:"
    curl -s "http://localhost:8080/api/a/flaky?failRate=80"
    echo ""
done

echo ""
echo "📊 Final circuit breaker metrics:"
curl -s $SERVICE_URL/actuator/prometheus | grep "resilience4j_circuitbreaker"