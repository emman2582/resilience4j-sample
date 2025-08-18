#!/bin/bash

# Docker Compose Resilience4j Testing Script
# Simple tests for Docker Compose deployment

SERVICE_URL="http://localhost:8080"

echo "🐳 Docker Compose Resilience4j Testing"
echo "======================================="
echo ""

# Function to check if service is ready
wait_for_service() {
    echo "⏳ Waiting for services to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$SERVICE_URL/actuator/health" | grep -q "UP"; then
            echo "✅ Service A is ready!"
            return 0
        fi
        echo "  Attempt $attempt/$max_attempts - Service not ready yet..."
        sleep 2
        ((attempt++))
    done
    
    echo "❌ Service failed to start within timeout"
    return 1
}

# Test basic connectivity
test_connectivity() {
    echo "1. Testing Basic Connectivity"
    echo "============================="
    
    response=$(curl -s "$SERVICE_URL/api/a/ok")
    if echo "$response" | grep -q "OK"; then
        echo "✅ Basic endpoint: $response"
    else
        echo "❌ Basic endpoint failed: $response"
        return 1
    fi
    echo ""
}

# Test circuit breaker
test_circuit_breaker() {
    echo "2. Testing Circuit Breaker"
    echo "=========================="
    
    echo "📊 Normal requests (0% failure):"
    for i in {1..3}; do
        response=$(curl -s "$SERVICE_URL/api/a/flaky?failRate=0")
        echo "  Request $i: $response"
    done
    
    echo ""
    echo "📊 High failure rate (80% failure):"
    for i in {1..5}; do
        response=$(curl -s "$SERVICE_URL/api/a/flaky?failRate=80")
        echo "  Request $i: $response"
        sleep 0.5
    done
    echo ""
}

# Test timeout
test_timeout() {
    echo "3. Testing Timeout/TimeLimiter"
    echo "=============================="
    
    echo "📊 Fast request (500ms):"
    response=$(curl -s "$SERVICE_URL/api/a/slow?delayMs=500")
    echo "  Fast: $response"
    
    echo ""
    echo "📊 Slow request (3000ms - should timeout):"
    response=$(curl -s "$SERVICE_URL/api/a/slow?delayMs=3000")
    echo "  Slow: $response"
    echo ""
}

# Test bulkhead
test_bulkhead() {
    echo "4. Testing Bulkhead Isolation"
    echo "============================="
    
    echo "📊 Testing bulkhead X (3 permits):"
    for i in {1..4}; do
        response=$(curl -s "$SERVICE_URL/api/a/bulkhead/x")
        echo "  Request $i: $response"
    done
    
    echo ""
    echo "📊 Testing bulkhead Y (2 permits):"
    for i in {1..3}; do
        response=$(curl -s "$SERVICE_URL/api/a/bulkhead/y")
        echo "  Request $i: $response"
    done
    echo ""
}

# Test rate limiter
test_rate_limiter() {
    echo "5. Testing Rate Limiter"
    echo "======================="
    
    echo "📊 Rapid requests (should hit rate limit):"
    for i in {1..8}; do
        response=$(curl -s "$SERVICE_URL/api/a/limited")
        echo "  Request $i: $response"
        sleep 0.1
    done
    echo ""
}

# Check metrics
check_metrics() {
    echo "6. Checking Metrics"
    echo "=================="
    
    echo "📊 Circuit breaker metrics:"
    curl -s "$SERVICE_URL/actuator/prometheus" | grep "resilience4j_circuitbreaker_state" | head -3
    
    echo ""
    echo "📊 Bulkhead metrics:"
    curl -s "$SERVICE_URL/actuator/prometheus" | grep "resilience4j_bulkhead_available_concurrent_calls"
    
    echo ""
    echo "📊 Rate limiter metrics:"
    curl -s "$SERVICE_URL/actuator/prometheus" | grep "resilience4j_ratelimiter_available_permissions"
    echo ""
}

# Main execution
main() {
    if ! wait_for_service; then
        echo "❌ Cannot proceed with tests - service is not available"
        echo ""
        echo "💡 Make sure Docker Compose is running:"
        echo "   docker compose up -d"
        exit 1
    fi
    
    test_connectivity || exit 1
    test_circuit_breaker
    test_timeout
    test_bulkhead
    test_rate_limiter
    check_metrics
    
    echo "✅ All tests completed!"
    echo ""
    echo "📊 View metrics at:"
    echo "   • Prometheus: http://localhost:9090"
    echo "   • Grafana: http://localhost:3000 (admin/admin)"
    echo "   • Service metrics: http://localhost:8080/actuator/prometheus"
}

# Run tests
main