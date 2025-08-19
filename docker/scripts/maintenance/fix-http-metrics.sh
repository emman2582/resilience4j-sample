#!/bin/bash
echo "🔧 Fixing HTTP server metrics..."

cd "$(dirname "$0")/../.."

echo
echo "1. Enabling Prometheus export in services..."

# Enable Prometheus in service-a
cat > ../service-a/src/main/resources/application.yml << 'EOF'
server:
  port: 8080

b:
  url: ${B_URL:http://localhost:8081}

logging:
  level:
    root: WARN
    com.example.a: INFO
    io.github.resilience4j: DEBUG

management:
  endpoints:
    web:
      exposure:
        include: [health, info, metrics, prometheus]
  metrics:
    web:
      server:
        request:
          autotime:
            enabled: true
    distribution:
      percentiles-histogram:
        http.server.requests: true
      slo:
        http.server.requests: 10ms,50ms,100ms,200ms,500ms,1s,2s,5s
    export:
      prometheus:
        enabled: true
        histogram-flavor: prometheus

resilience4j:
  circuitbreaker:
    instances:
      backendB:
        slidingWindowType: COUNT_BASED
        slidingWindowSize: 6
        minimumNumberOfCalls: 3
        failureRateThreshold: 50
        automaticTransitionFromOpenToHalfOpenEnabled: true
        waitDurationInOpenState: 5s
      timeoutBreaker:
        slidingWindowType: COUNT_BASED
        slidingWindowSize: 4
        minimumNumberOfCalls: 2
        failureRateThreshold: 50
        slowCallRateThreshold: 50
        slowCallDurationThreshold: 2s
        automaticTransitionFromOpenToHalfOpenEnabled: true
        waitDurationInOpenState: 3s
  retry:
    instances:
      backendB:
        maxAttempts: 3
        waitDuration: 200ms
        enableExponentialBackoff: true
        exponentialBackoffMultiplier: 2.0
        retryExceptions:
          - java.io.IOException
          - org.springframework.web.client.ResourceAccessException
          - org.springframework.web.client.HttpServerErrorException
        ignoreExceptions:
          - io.github.resilience4j.circuitbreaker.CallNotPermittedException
  ratelimiter:
    instances:
      backendB:
        limitForPeriod: 5
        limitRefreshPeriod: 1s
        timeoutDuration: 1s
  timelimiter:
    instances:
      timelimiterB:
        timeoutDuration: 2s
        cancelRunningFuture: true
  bulkhead:
    instances:
      bhX:
        type: SEMAPHORE
        maxConcurrentCalls: 2
        maxWaitDuration: 100ms
      bhY:
        type: SEMAPHORE
        maxConcurrentCalls: 1
        maxWaitDuration: 100ms
  metrics:
    enabled: true
    export:
      prometheus:
        enabled: true
EOF

# Enable Prometheus in service-b
cat > ../service-b/src/main/resources/application.yml << 'EOF'
server:
  port: 8081

logging:
  level:
    root: WARN
    com.example.b: INFO

management:
  endpoints:
    web:
      exposure:
        include: [health, info, metrics, prometheus]
  metrics:
    web:
      server:
        request:
          autotime:
            enabled: true
    distribution:
      percentiles-histogram:
        http.server.requests: true
      slo:
        http.server.requests: 10ms,50ms,100ms,200ms,500ms,1s,2s,5s
    export:
      prometheus:
        enabled: true
        histogram-flavor: prometheus
EOF

echo "✅ Prometheus export enabled"

echo
echo "2. Rebuilding services..."
./build.sh

echo
echo "3. Restarting services..."
docker compose restart service-a service-b

echo
echo "4. Waiting for services..."
sleep 25

echo
echo "5. Testing HTTP metrics endpoints..."
echo "Service A metrics:"
HTTP_A_COUNT=$(curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests" | wc -l)
echo "   HTTP metrics count: $HTTP_A_COUNT"

echo "Service B metrics:"
HTTP_B_COUNT=$(curl -s http://localhost:8081/actuator/prometheus | grep "http_server_requests" | wc -l)
echo "   HTTP metrics count: $HTTP_B_COUNT"

echo
echo "6. Generating traffic to create metrics..."
for i in {1..10}; do
    curl -s http://localhost:8080/api/a/ok > /dev/null
    curl -s http://localhost:8080/api/a/slow?delayMs=500 > /dev/null
done

echo
echo "7. Checking specific HTTP metrics..."
sleep 5

echo "http_server_requests_total:"
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_total" | head -3

echo
echo "http_server_requests_seconds_bucket:"
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_seconds_bucket" | head -3

echo
echo "8. Verifying Prometheus scraping..."
sleep 10
PROM_HTTP_METRICS=$(curl -s "http://localhost:9090/api/v1/query?query=http_server_requests_total" | grep -o '"value":\[[^]]*\]' | wc -l)
echo "HTTP metrics in Prometheus: $PROM_HTTP_METRICS"

if [ "$PROM_HTTP_METRICS" -gt 0 ]; then
    echo "✅ HTTP server metrics working!"
else
    echo "❌ HTTP metrics still not in Prometheus"
fi

echo
echo "🎯 HTTP server metrics should now be available!"
echo "📊 Check Grafana dashboard: http://localhost:3000/d/otel-sli-slo-dashboard"