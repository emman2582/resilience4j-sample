#!/bin/bash

# Resilience4j Pattern Testing Script
# This script tests all resilience patterns with various scenarios

NAMESPACE="r4j-monitoring"
BASE_URL="http://localhost:8080"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}$1${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

print_test() {
    echo -e "${YELLOW}Testing:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if services are accessible
check_connectivity() {
    print_header "🔍 CONNECTIVITY CHECK"
    
    print_test "Service A health check"
    if curl -s "$BASE_URL/actuator/health" | grep -q "UP"; then
        print_success "Service A is healthy"
    else
        print_error "Service A is not accessible"
        echo "Make sure port forwarding is active: kubectl port-forward svc/service-a 8080:8080 -n $NAMESPACE"
        exit 1
    fi
    
    print_test "Basic API endpoint"
    response=$(curl -s "$BASE_URL/api/a/ok")
    if echo "$response" | grep -q "OK"; then
        print_success "Basic endpoint working: $response"
    else
        print_error "Basic endpoint failed: $response"
    fi
    echo ""
}

# Test Circuit Breaker pattern
test_circuit_breaker() {
    print_header "⚡ CIRCUIT BREAKER PATTERN"
    
    print_test "Normal operation (should succeed)"
    for i in {1..3}; do
        response=$(curl -s "$BASE_URL/api/a/flaky?failRate=0")
        echo "  Request $i: $response"
    done
    
    echo ""
    print_test "High failure rate (should trigger circuit breaker)"
    for i in {1..10}; do
        response=$(curl -s "$BASE_URL/api/a/flaky?failRate=80")
        echo "  Request $i: $response"
        sleep 0.5
    done
    
    echo ""
    print_test "Circuit breaker recovery (wait 10 seconds)"
    sleep 10
    for i in {1..3}; do
        response=$(curl -s "$BASE_URL/api/a/flaky?failRate=0")
        echo "  Recovery $i: $response"
        sleep 1
    done
    echo ""
}

# Test Retry pattern
test_retry() {
    print_header "🔄 RETRY PATTERN"
    
    print_test "Moderate failure rate (should retry and eventually succeed)"
    for i in {1..5}; do
        response=$(curl -s "$BASE_URL/api/a/flaky?failRate=40")
        echo "  Request $i: $response"
        sleep 1
    done
    echo ""
}

# Test TimeLimiter pattern
test_timelimiter() {
    print_header "⏱️ TIME LIMITER PATTERN"
    
    print_test "Fast response (should succeed)"
    response=$(curl -s "$BASE_URL/api/a/slow?delayMs=500")
    echo "  Fast request: $response"
    
    print_test "Slow response (should timeout and fallback)"
    response=$(curl -s "$BASE_URL/api/a/slow?delayMs=3000")
    echo "  Slow request: $response"
    
    print_test "Very slow response (should timeout quickly)"
    response=$(curl -s "$BASE_URL/api/a/slow?delayMs=5000")
    echo "  Very slow request: $response"
    echo ""
}

# Test Bulkhead pattern
test_bulkhead() {
    print_header "🚧 BULKHEAD PATTERN"
    
    print_test "Bulkhead X (3 permits available)"
    for i in {1..5}; do
        response=$(curl -s "$BASE_URL/api/a/bulkhead/x")
        echo "  Request $i to X: $response"
    done
    
    echo ""
    print_test "Bulkhead Y (2 permits available)"
    for i in {1..4}; do
        response=$(curl -s "$BASE_URL/api/a/bulkhead/y")
        echo "  Request $i to Y: $response"
    done
    
    echo ""
    print_test "Concurrent requests to both bulkheads"
    for i in {1..3}; do
        curl -s "$BASE_URL/api/a/bulkhead/x" &
        curl -s "$BASE_URL/api/a/bulkhead/y" &
    done
    wait
    echo "  Concurrent requests completed"
    echo ""
}

# Test Rate Limiter pattern
test_ratelimiter() {
    print_header "🚦 RATE LIMITER PATTERN"
    
    print_test "Rate limiter (5 requests per second limit)"
    for i in {1..10}; do
        response=$(curl -s "$BASE_URL/api/a/limited")
        echo "  Request $i: $response"
        sleep 0.1  # Send requests faster than the limit
    done
    
    echo ""
    print_test "Wait and retry (should allow requests again)"
    sleep 2
    for i in {1..3}; do
        response=$(curl -s "$BASE_URL/api/a/limited")
        echo "  Retry $i: $response"
        sleep 1
    done
    echo ""
}

# Test combined patterns
test_combined_patterns() {
    print_header "🔗 COMBINED PATTERNS"
    
    print_test "Slow + flaky endpoint (multiple patterns active)"
    for i in {1..5}; do
        response=$(curl -s "$BASE_URL/api/a/slow?delayMs=1500&failRate=30")
        echo "  Combined test $i: $response"
        sleep 1
    done
    echo ""
}

# Check metrics
check_metrics() {
    print_header "📊 METRICS CHECK"
    
    print_test "Resilience4j metrics availability"
    metrics=$(curl -s "$BASE_URL/actuator/prometheus" | grep resilience4j | head -5)
    if [ -n "$metrics" ]; then
        print_success "Metrics are available"
        echo "$metrics"
    else
        print_error "No Resilience4j metrics found"
    fi
    
    echo ""
    print_test "Circuit breaker metrics"
    cb_metrics=$(curl -s "$BASE_URL/actuator/prometheus" | grep resilience4j_circuitbreaker)
    if [ -n "$cb_metrics" ]; then
        echo "$cb_metrics" | head -3
    fi
    
    echo ""
    print_test "Bulkhead metrics"
    bulkhead_metrics=$(curl -s "$BASE_URL/actuator/prometheus" | grep resilience4j_bulkhead)
    if [ -n "$bulkhead_metrics" ]; then
        echo "$bulkhead_metrics" | head -3
    fi
    echo ""
}

# Performance test
performance_test() {
    print_header "🚀 PERFORMANCE TEST"
    
    print_test "Load test with 50 concurrent requests"
    for i in {1..50}; do
        curl -s "$BASE_URL/api/a/ok" &
    done
    wait
    print_success "Load test completed"
    
    print_test "Mixed pattern load test"
    for i in {1..20}; do
        curl -s "$BASE_URL/api/a/flaky?failRate=20" &
        curl -s "$BASE_URL/api/a/slow?delayMs=1000" &
        curl -s "$BASE_URL/api/a/limited" &
    done
    wait
    print_success "Mixed load test completed"
    echo ""
}

# Main test execution
main() {
    echo "🧪 Starting Resilience4j Pattern Testing"
    echo "========================================"
    echo ""
    
    check_connectivity
    test_circuit_breaker
    test_retry
    test_timelimiter
    test_bulkhead
    test_ratelimiter
    test_combined_patterns
    check_metrics
    performance_test
    
    print_header "✅ TESTING COMPLETED"
    echo "All resilience patterns have been tested!"
    echo ""
    echo "📊 Next steps:"
    echo "• Check Prometheus metrics: http://localhost:9090"
    echo "• View Grafana dashboards: http://localhost:3000"
    echo "• Monitor application logs: kubectl logs -l app.kubernetes.io/name=service-a -n $NAMESPACE"
}

# Check if port forwarding is active
if ! curl -s "$BASE_URL/actuator/health" > /dev/null; then
    echo "❌ Service A is not accessible at $BASE_URL"
    echo ""
    echo "Please ensure port forwarding is active:"
    echo "kubectl port-forward svc/service-a 8080:8080 -n $NAMESPACE"
    echo ""
    echo "Or run the port-forward script:"
    echo "./port-forward.sh"
    exit 1
fi

# Run tests
main