#!/bin/bash
echo "🔍 Diagnosing missing metrics..."

echo
echo "1. Testing service endpoints directly:"
echo "Service A Prometheus endpoint:"
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests" | wc -l

echo "Service B Prometheus endpoint:"
curl -s http://localhost:8081/actuator/prometheus | grep "http_server_requests" | wc -l

echo
echo "2. Generating traffic to create metrics:"
for i in {1..5}; do
    curl -s http://localhost:8080/api/a/ok > /dev/null
    echo "Request $i sent"
done

echo
echo "3. Checking metrics after traffic:"
sleep 3
echo "Service A http_server_requests_total:"
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_total"

echo
echo "4. Checking OTel Collector:"
echo "Port 8888 (internal):"
curl -s http://localhost:8888/metrics | grep "otelcol_receiver_accepted_spans_total"

echo "Port 9464 (export):"
curl -s http://localhost:9464/metrics | grep "http_server_requests" | wc -l

echo
echo "5. Checking Prometheus targets:"
curl -s http://localhost:9090/api/v1/targets | grep -A3 -B3 "service-a"

echo
echo "6. Testing Prometheus queries:"
curl -s "http://localhost:9090/api/v1/query?query=up" | grep "service-a"