#!/bin/bash
echo "📊 How Prometheus Scrapes OpenTelemetry Metrics in This Project"
echo "================================================================"

echo
echo "🔄 Current Architecture:"
echo "Services → OTLP → OTel Collector → Prometheus Format → Prometheus Scraping"

echo
echo "1️⃣ Services Export via OTLP:"
echo "   service-a:8080 ──OTLP──┐"
echo "   service-b:8081 ──OTLP──┤"
echo "                          ├──→ otel-collector:4318"
echo "   (HTTP/Protobuf)        │"
echo "                          └──→ Receives metrics"

echo
echo "2️⃣ OTel Collector Processing:"
echo "   Receives OTLP → Batch Processing → Exports to Prometheus format"
echo "   Port 4318: OTLP HTTP receiver"
echo "   Port 9464: Prometheus exporter"
echo "   Port 8888: Internal metrics"

echo
echo "3️⃣ Prometheus Scraping Configuration:"
echo "   Job 'otel-collector': scrapes otel-collector:9464/metrics"
echo "   Job 'otel-collector-internal': scrapes otel-collector:8888/metrics"
echo "   Job 'service-a': scrapes service-a:8080/actuator/prometheus"
echo "   Job 'service-b': scrapes service-b:8081/actuator/prometheus"

echo
echo "🔍 Testing Current Setup:"

echo
echo "A. Checking OTel Collector OTLP Receiver:"
OTLP_RECEIVED=$(curl -s http://localhost:8888/metrics | grep "otelcol_receiver_accepted_metric_points_total")
echo "   OTLP metrics received: $OTLP_RECEIVED"

echo
echo "B. Checking OTel Collector Prometheus Export:"
PROM_EXPORTED=$(curl -s http://localhost:9464/metrics | grep -E "(http_server_requests|resilience4j_)" | wc -l)
echo "   Prometheus format metrics: $PROM_EXPORTED entries"

echo
echo "C. Checking Prometheus Scraping:"
PROM_TARGETS=$(curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"up"' | wc -l)
echo "   Prometheus healthy targets: $PROM_TARGETS"

echo
echo "D. Sample metrics from each endpoint:"
echo
echo "   From OTel Collector (port 9464):"
curl -s http://localhost:9464/metrics | grep "http_server_requests_total" | head -2

echo
echo "   From Service A (port 8080):"
curl -s http://localhost:8080/actuator/prometheus | grep "http_server_requests_total" | head -2

echo
echo "📋 Prometheus Targets Status:"
curl -s http://localhost:9090/api/v1/targets | grep -E '"job"|"health"' | head -10

echo
echo "🎯 Summary:"
echo "   ✅ Services export via OTLP to OTel Collector"
echo "   ✅ OTel Collector converts to Prometheus format"
echo "   ✅ Prometheus scrapes both OTel Collector and direct service endpoints"
echo "   ✅ This provides redundancy and OTel-specific metrics"

echo
echo "🔧 Access Points:"
echo "   Prometheus UI: http://localhost:9090"
echo "   OTel Metrics: http://localhost:9464/metrics"
echo "   Service A: http://localhost:8080/actuator/prometheus"
echo "   Service B: http://localhost:8081/actuator/prometheus"