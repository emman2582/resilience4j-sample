#!/bin/bash
echo "🔍 Verifying OpenTelemetry Implementation..."

echo
echo "1. Checking service health..."
SERVICE_A=$(curl -s http://localhost:8080/actuator/health | grep -o '"status":"UP"' | wc -l)
SERVICE_B=$(curl -s http://localhost:8081/actuator/health | grep -o '"status":"UP"' | wc -l)

if [ "$SERVICE_A" -eq 1 ] && [ "$SERVICE_B" -eq 1 ]; then
    echo "✅ Services are healthy"
else
    echo "❌ Services not healthy - stopping test"
    exit 1
fi

echo
echo "2. Checking OTel collector..."
OTEL_UP=$(curl -s http://localhost:8888/metrics | grep "otelcol_process_uptime" | wc -l)
if [ "$OTEL_UP" -gt 0 ]; then
    echo "✅ OTel collector is running"
else
    echo "❌ OTel collector not responding"
    exit 1
fi

echo
echo "3. Generating test traffic..."
echo "   - Basic requests..."
curl -s http://localhost:8080/api/a/ok > /dev/null
curl -s http://localhost:8080/api/a/ok > /dev/null

echo "   - TimeLimiter test (fast)..."
curl -s "http://localhost:8080/api/a/slow?delayMs=500" > /dev/null

echo "   - TimeLimiter test (timeout)..."
curl -s "http://localhost:8080/api/a/slow?delayMs=3000" > /dev/null

echo "   - Circuit breaker test..."
curl -s "http://localhost:8080/api/a/flaky?failRate=80" > /dev/null
curl -s "http://localhost:8080/api/a/flaky?failRate=80" > /dev/null

echo "   - Rate limiter test..."
for i in {1..8}; do
    curl -s http://localhost:8080/api/a/limited > /dev/null
done

echo
echo "4. Waiting for metrics export..."
sleep 10

echo
echo "5. Verifying exported metrics..."
METRICS=$(curl -s http://localhost:9464/metrics)

# Check HTTP metrics
HTTP_COUNT=$(echo "$METRICS" | grep "http_server_requests_total" | wc -l)
echo "   HTTP request metrics: $HTTP_COUNT entries"

# Check Resilience4j metrics
R4J_CB=$(echo "$METRICS" | grep "resilience4j_circuitbreaker" | wc -l)
echo "   Circuit breaker metrics: $R4J_CB entries"

R4J_TL=$(echo "$METRICS" | grep "resilience4j_timelimiter" | wc -l)
echo "   TimeLimiter metrics: $R4J_TL entries"

R4J_RL=$(echo "$METRICS" | grep "resilience4j_ratelimiter" | wc -l)
echo "   Rate limiter metrics: $R4J_RL entries"

# Check OTel internal metrics
OTEL_RECEIVED=$(echo "$METRICS" | grep "otelcol_receiver_accepted_metric_points_total" | wc -l)
echo "   OTel receiver metrics: $OTEL_RECEIVED entries"

echo
echo "6. Test Results Summary:"
if [ "$HTTP_COUNT" -gt 0 ]; then
    echo "✅ HTTP server metrics working"
else
    echo "❌ HTTP server metrics missing"
fi

if [ "$R4J_CB" -gt 0 ]; then
    echo "✅ Circuit breaker metrics working"
else
    echo "❌ Circuit breaker metrics missing"
fi

if [ "$R4J_TL" -gt 0 ]; then
    echo "✅ TimeLimiter metrics working"
else
    echo "❌ TimeLimiter metrics missing"
fi

if [ "$R4J_RL" -gt 0 ]; then
    echo "✅ Rate limiter metrics working"
else
    echo "❌ Rate limiter metrics missing"
fi

if [ "$OTEL_RECEIVED" -gt 0 ]; then
    echo "✅ OpenTelemetry pipeline working"
else
    echo "❌ OpenTelemetry pipeline not working"
fi

echo
echo "7. Sample metrics:"
echo "HTTP requests:"
echo "$METRICS" | grep "http_server_requests_total" | head -2

echo
echo "TimeLimiter calls:"
echo "$METRICS" | grep "resilience4j_timelimiter_calls_total" | head -2

echo
echo "🎯 OpenTelemetry verification complete!"
echo "📊 Grafana data source: http://otel-collector:9464"