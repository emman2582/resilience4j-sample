@echo off
echo Fixing OpenTelemetry and HTTP server metrics...

echo.
echo 1. Rebuilding with OpenTelemetry dependencies...
cd /d "%~dp0..\.."
call build.bat

echo.
echo 2. Restarting stack with updated OTel config...
docker compose down
docker compose up -d

echo.
echo 3. Waiting for services to initialize...
timeout /t 45 /nobreak > nul

echo.
echo 4. Generating traffic to create metrics...
curl -s http://localhost:8080/api/a/ok > nul
curl -s http://localhost:8080/api/a/flaky?failRate=20 > nul
curl -s http://localhost:8080/api/a/slow?delayMs=800 > nul
curl -s http://localhost:8080/api/a/limited > nul

echo.
echo 5. Checking OTel collector internal metrics...
echo OTel collector spans:
curl -s http://localhost:8888/metrics | findstr "otelcol_receiver_accepted_spans_total\|otelcol_exporter_sent_spans_total"

echo.
echo 6. Checking HTTP server metrics...
echo Service A HTTP duration buckets:
curl -s http://localhost:8080/actuator/prometheus | findstr "http_server_duration_bucket"

echo.
echo Service A HTTP requests total:
curl -s http://localhost:8080/actuator/prometheus | findstr "http_server_requests_total"

echo.
echo Service A active requests:
curl -s http://localhost:8080/actuator/prometheus | findstr "http_server_active_requests"

echo.
echo 7. Checking OTel exported metrics...
echo OTel collector exported metrics:
curl -s http://localhost:9464/metrics | findstr "http_server"

echo.
echo OpenTelemetry metrics fix complete!
echo - OTel internal metrics: http://localhost:8888/metrics
echo - OTel exported metrics: http://localhost:9464/metrics
echo - Prometheus: http://localhost:9090
echo - Grafana: http://localhost:3000