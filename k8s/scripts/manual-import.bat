@echo off
setlocal

set GRAFANA_URL=http://localhost:3000
set GRAFANA_USER=admin
set GRAFANA_PASS=admin

echo Creating Enhanced Dashboard manually...
curl -X POST -H "Content-Type: application/json" -u "%GRAFANA_USER%:%GRAFANA_PASS%" -d "{\"dashboard\":{\"title\":\"Enhanced Resilience4j Dashboard\",\"panels\":[{\"title\":\"Circuit Breaker State\",\"type\":\"stat\",\"targets\":[{\"expr\":\"resilience4j_circuitbreaker_state\",\"legendFormat\":\"{{name}}\"}],\"gridPos\":{\"h\":8,\"w\":12,\"x\":0,\"y\":0}},{\"title\":\"HTTP Request Rate\",\"type\":\"graph\",\"targets\":[{\"expr\":\"rate(http_server_requests_seconds_count[5m])\",\"legendFormat\":\"{{method}} {{uri}}\"}],\"gridPos\":{\"h\":8,\"w\":12,\"x\":12,\"y\":0}},{\"title\":\"Bulkhead Status\",\"type\":\"graph\",\"targets\":[{\"expr\":\"resilience4j_bulkhead_available_concurrent_calls\",\"legendFormat\":\"{{name}} Available\"}],\"gridPos\":{\"h\":8,\"w\":12,\"x\":0,\"y\":8}},{\"title\":\"Rate Limiter\",\"type\":\"graph\",\"targets\":[{\"expr\":\"resilience4j_ratelimiter_available_permissions\",\"legendFormat\":\"{{name}} Available\"}],\"gridPos\":{\"h\":8,\"w\":12,\"x\":12,\"y\":8}}],\"time\":{\"from\":\"now-1h\",\"to\":\"now\"},\"refresh\":\"5s\"},\"overwrite\":true}" "%GRAFANA_URL%/api/dashboards/db"

echo.
echo Creating Golden Metrics Dashboard manually...
curl -X POST -H "Content-Type: application/json" -u "%GRAFANA_USER%:%GRAFANA_PASS%" -d "{\"dashboard\":{\"title\":\"Golden Metrics - Resilience4j\",\"panels\":[{\"title\":\"Throughput\",\"type\":\"graph\",\"targets\":[{\"expr\":\"rate(http_server_requests_seconds_count[5m])\",\"legendFormat\":\"{{uri}} Requests/sec\"}],\"gridPos\":{\"h\":8,\"w\":12,\"x\":0,\"y\":0}},{\"title\":\"Latency\",\"type\":\"graph\",\"targets\":[{\"expr\":\"rate(http_server_requests_seconds_sum[5m]) / rate(http_server_requests_seconds_count[5m]) * 1000\",\"legendFormat\":\"{{uri}} Avg Latency (ms)\"}],\"gridPos\":{\"h\":8,\"w\":12,\"x\":12,\"y\":0}},{\"title\":\"Error Rate\",\"type\":\"graph\",\"targets\":[{\"expr\":\"rate(http_server_requests_seconds_count{status=~\\\"5..\\\"}[5m])\",\"legendFormat\":\"{{uri}} Errors/sec\"}],\"gridPos\":{\"h\":8,\"w\":12,\"x\":0,\"y\":8}},{\"title\":\"Saturation\",\"type\":\"graph\",\"targets\":[{\"expr\":\"process_cpu_usage * 100\",\"legendFormat\":\"{{instance}} CPU %%\"}],\"gridPos\":{\"h\":8,\"w\":12,\"x\":12,\"y\":8}}],\"time\":{\"from\":\"now-1h\",\"to\":\"now\"},\"refresh\":\"5s\"},\"overwrite\":true}" "%GRAFANA_URL%/api/dashboards/db"

echo.
echo Done! Check Grafana at %GRAFANA_URL%