#!/bin/bash

echo "🧪 Generating test traces..."
echo "💡 Tip: Use ./test-otel-comprehensive.sh for full dashboard data generation"

# Basic requests
echo "Testing basic endpoints..."
curl -s http://localhost:8080/api/a/ok
curl -s http://localhost:8080/api/a/ok

# Circuit breaker patterns
echo "Testing circuit breaker..."
curl -s "http://localhost:8080/api/a/flaky?failRate=30"
curl -s "http://localhost:8080/api/a/flaky?failRate=30"

# Timeout patterns
echo "Testing timeouts..."
curl -s "http://localhost:8080/api/a/slow?delayMs=1000"
curl -s "http://localhost:8080/api/a/slow?delayMs=2000"

# Bulkhead patterns
echo "Testing bulkhead..."
curl -s http://localhost:8080/api/a/bulkhead/x
curl -s http://localhost:8080/api/a/bulkhead/y

# Rate limiter
echo "Testing rate limiter..."
for i in {1..10}; do
  curl -s http://localhost:8080/api/a/limited &
done
wait

echo "✅ Basic test traces generated!"
echo "🔍 View traces at: http://localhost:16686"
echo "📊 View metrics at: http://localhost:3000"
echo ""
echo "🚀 For comprehensive dashboard testing:"
echo "   ./test-otel-comprehensive.sh    # Full 5-minute test"
echo "   ./test-dashboard-quick.sh       # Quick 2-minute test"