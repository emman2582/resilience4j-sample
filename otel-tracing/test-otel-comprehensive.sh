#!/bin/bash

# Comprehensive OpenTelemetry Test Script
# Generates data for all Grafana dashboard panels

BASE_URL="http://localhost:8080"
DURATION=300  # 5 minutes of testing
CONCURRENT_USERS=5

echo "🚀 Starting comprehensive OpenTelemetry test..."
echo "📊 Generating data for Grafana dashboard panels"
echo "⏱️  Test duration: ${DURATION} seconds"
echo "👥 Concurrent users: ${CONCURRENT_USERS}"

# Function to make requests with different patterns
make_requests() {
    local endpoint=$1
    local count=$2
    local delay=$3
    
    for i in $(seq 1 $count); do
        curl -s "$BASE_URL$endpoint" > /dev/null &
        sleep $delay
    done
}

# Function to generate circuit breaker failures
generate_circuit_breaker_data() {
    echo "🔴 Generating Circuit Breaker data..."
    
    # Generate failures to trigger circuit breaker
    for i in {1..20}; do
        curl -s "$BASE_URL/api/a/flaky?failRate=80" > /dev/null &
        sleep 0.1
    done
    
    # Wait for circuit breaker to open
    sleep 5
    
    # Continue making requests to show open state
    for i in {1..10}; do
        curl -s "$BASE_URL/api/a/flaky?failRate=80" > /dev/null &
        sleep 0.5
    done
}

# Function to generate timeout scenarios
generate_timeout_data() {
    echo "⏰ Generating Timeout data..."
    
    # Generate slow requests to trigger timeouts
    for i in {1..15}; do
        curl -s "$BASE_URL/api/a/slow?delayMs=3000" > /dev/null &
        sleep 0.2
    done
}

# Function to generate bulkhead data
generate_bulkhead_data() {
    echo "🚧 Generating Bulkhead data..."
    
    # Saturate bulkhead X
    for i in {1..10}; do
        curl -s "$BASE_URL/api/a/bulkhead/x" > /dev/null &
    done
    
    # Saturate bulkhead Y
    for i in {1..8}; do
        curl -s "$BASE_URL/api/a/bulkhead/y" > /dev/null &
    done
    
    sleep 2
}

# Function to generate rate limiter data
generate_rate_limiter_data() {
    echo "🚦 Generating Rate Limiter data..."
    
    # Burst requests to trigger rate limiting
    for i in {1..20}; do
        curl -s "$BASE_URL/api/a/limited" > /dev/null &
    done
    
    sleep 1
}

# Function to generate normal traffic
generate_normal_traffic() {
    echo "✅ Generating Normal traffic..."
    
    # Steady normal requests
    for i in {1..30}; do
        curl -s "$BASE_URL/api/a/ok" > /dev/null &
        sleep 0.1
    done
}

# Function to generate retry pattern data
generate_retry_data() {
    echo "🔄 Generating Retry pattern data..."
    
    # Intermittent failures to trigger retries
    for i in {1..15}; do
        curl -s "$BASE_URL/api/a/flaky?failRate=40" > /dev/null &
        sleep 0.3
    done
}

# Main test execution
run_comprehensive_test() {
    local end_time=$((SECONDS + DURATION))
    
    while [ $SECONDS -lt $end_time ]; do
        echo "🔄 Test cycle at $(date '+%H:%M:%S')"
        
        # Generate different patterns in parallel
        generate_normal_traffic &
        generate_circuit_breaker_data &
        generate_timeout_data &
        generate_bulkhead_data &
        generate_rate_limiter_data &
        generate_retry_data &
        
        # Wait for current cycle to complete
        wait
        
        echo "📈 Cycle complete, waiting 10s..."
        sleep 10
    done
}

# Performance test for high throughput metrics
run_performance_test() {
    echo "🏃 Running performance test for 60 seconds..."
    
    local perf_end=$((SECONDS + 60))
    
    while [ $SECONDS -lt $perf_end ]; do
        # High-frequency requests
        for user in $(seq 1 $CONCURRENT_USERS); do
            {
                curl -s "$BASE_URL/api/a/ok" > /dev/null
                curl -s "$BASE_URL/api/a/flaky?failRate=20" > /dev/null
                curl -s "$BASE_URL/api/a/slow?delayMs=500" > /dev/null
            } &
        done
        
        sleep 0.1
    done
    
    wait
}

# Test specific dashboard panels
test_dashboard_panels() {
    echo "📊 Testing specific dashboard panels..."
    
    # Panel 1: Trace Reception Rate
    echo "  📡 Generating traces for reception rate..."
    for i in {1..50}; do
        curl -s "$BASE_URL/api/a/ok" > /dev/null &
        sleep 0.05
    done
    
    # Panel 2: Request Latency (P95/P99)
    echo "  ⏱️  Generating latency variations..."
    curl -s "$BASE_URL/api/a/slow?delayMs=100" > /dev/null &
    curl -s "$BASE_URL/api/a/slow?delayMs=500" > /dev/null &
    curl -s "$BASE_URL/api/a/slow?delayMs=1000" > /dev/null &
    curl -s "$BASE_URL/api/a/slow?delayMs=2000" > /dev/null &
    
    # Panel 3: Transaction Rate
    echo "  📈 Generating transaction rate data..."
    for i in {1..25}; do
        curl -s "$BASE_URL/api/a/ok" > /dev/null &
        curl -s "$BASE_URL/api/a/flaky?failRate=10" > /dev/null &
    done
    
    # Panel 4: Error Rate
    echo "  ❌ Generating error rate data..."
    for i in {1..10}; do
        curl -s "$BASE_URL/api/a/flaky?failRate=70" > /dev/null &
    done
    
    # Panel 5: Circuit Breaker States
    echo "  🔴 Triggering circuit breaker states..."
    generate_circuit_breaker_data
    
    # Panel 6: Active Requests
    echo "  🔄 Creating active request load..."
    for i in {1..15}; do
        curl -s "$BASE_URL/api/a/slow?delayMs=2000" > /dev/null &
    done
    
    # Panel 7: Trace Export Rate
    echo "  📤 Generating trace export data..."
    for i in {1..40}; do
        curl -s "$BASE_URL/api/a/ok" > /dev/null &
        sleep 0.02
    done
    
    wait
}

# Health check
check_services() {
    echo "🏥 Checking service health..."
    
    if curl -s "$BASE_URL/actuator/health" | grep -q "UP"; then
        echo "✅ Service A is healthy"
    else
        echo "❌ Service A is not responding"
        exit 1
    fi
    
    if curl -s "http://localhost:8081/actuator/health" | grep -q "UP"; then
        echo "✅ Service B is healthy"
    else
        echo "❌ Service B is not responding"
        exit 1
    fi
}

# Main execution
main() {
    check_services
    
    echo "🎯 Starting dashboard panel tests..."
    test_dashboard_panels
    
    echo "🚀 Starting comprehensive test..."
    run_comprehensive_test &
    
    echo "🏃 Starting performance test..."
    run_performance_test &
    
    wait
    
    echo "✅ All tests completed!"
    echo "📊 Check Grafana dashboard: http://localhost:3000"
    echo "🔍 Check Jaeger traces: http://localhost:16686"
    echo "📈 Check Prometheus: http://localhost:9090"
}

# Trap to cleanup background processes
trap 'kill $(jobs -p) 2>/dev/null' EXIT

main "$@"