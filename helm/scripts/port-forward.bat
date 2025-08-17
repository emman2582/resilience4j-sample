@echo off
REM Port Forward Script for Resilience4j Stack (Windows)
REM This script sets up port forwarding for all services

set NAMESPACE=r4j-monitoring

echo 🔗 Setting up port forwarding for Resilience4j Stack...

REM Start port forwarding in separate windows
echo Starting port forwards...

start "Service A" cmd /k "kubectl port-forward svc/service-a 8080:8080 -n %NAMESPACE%"
timeout /t 2 /nobreak >nul

start "Service B" cmd /k "kubectl port-forward svc/service-b 8081:8081 -n %NAMESPACE%"
timeout /t 2 /nobreak >nul

start "Prometheus" cmd /k "kubectl port-forward svc/prometheus 9090:9090 -n %NAMESPACE%"
timeout /t 2 /nobreak >nul

start "Grafana" cmd /k "kubectl port-forward svc/grafana 3000:3000 -n %NAMESPACE%"
timeout /t 2 /nobreak >nul

start "OpenTelemetry Collector" cmd /k "kubectl port-forward svc/otel-collector 4318:4318 -n %NAMESPACE%"

echo.
echo ✅ Port forwarding windows opened!
echo.
echo 📋 Available Services:
echo =====================
echo 🔧 Service A (Main API):     http://localhost:8080
echo 🔧 Service B (Downstream):   http://localhost:8081
echo 📊 Prometheus (Metrics):     http://localhost:9090
echo 📈 Grafana (Dashboards):     http://localhost:3000
echo 🔍 OpenTelemetry Collector:  http://localhost:4318
echo.
echo 🧪 Test Commands:
echo ==================
echo curl http://localhost:8080/api/a/ok
echo curl "http://localhost:8080/api/a/flaky?failRate=60"
echo curl "http://localhost:8080/api/a/slow?delayMs=2500"
echo curl http://localhost:8080/api/a/bulkhead/x
echo curl http://localhost:8080/api/a/limited
echo.
echo 📊 Monitoring:
echo ==============
echo Prometheus Targets: http://localhost:9090/targets
echo Grafana Login: admin/admin
echo.
echo Close the individual port-forward windows to stop forwarding.

pause