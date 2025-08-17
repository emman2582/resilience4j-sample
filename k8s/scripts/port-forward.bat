@echo off
setlocal enabledelayedexpansion

set NAMESPACE=resilience4j-local

echo Checking pod status in namespace: %NAMESPACE%...
kubectl get pods -n %NAMESPACE%

echo.
echo Setting up port forwarding...

echo Cleaning up existing port-forwards...
taskkill /F /IM kubectl.exe >nul 2>&1

echo Checking for processes using target ports...
for %%p in (8080 8081 9090 3000 9464) do (
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%%p') do (
        if not "%%a"=="0" (
            taskkill /PID %%a /F >nul 2>&1
        )
    )
)

timeout /t 3 >nul

echo Setting up port-forward for service-a...
kubectl get pods -l app=service-a -n %NAMESPACE% -o jsonpath="{.items[0].metadata.name}" > temp_pod.txt 2>nul
set /p SERVICE_A_POD=<temp_pod.txt
if not "!SERVICE_A_POD!"=="" (
    start /B kubectl port-forward pod/!SERVICE_A_POD! 8080:8080 -n %NAMESPACE%
    echo Port-forward started for service-a on port 8080
) else (
    echo No pod found for service-a
)

echo Setting up port-forward for service-b...
kubectl get pods -l app=service-b -n %NAMESPACE% -o jsonpath="{.items[0].metadata.name}" > temp_pod.txt 2>nul
set /p SERVICE_B_POD=<temp_pod.txt
if not "!SERVICE_B_POD!"=="" (
    start /B kubectl port-forward pod/!SERVICE_B_POD! 8081:8081 -n %NAMESPACE%
    echo Port-forward started for service-b on port 8081
) else (
    echo No pod found for service-b
)

echo Setting up port-forward for prometheus...
kubectl get pods -l app=prometheus -n %NAMESPACE% -o jsonpath="{.items[0].metadata.name}" > temp_pod.txt 2>nul
set /p PROMETHEUS_POD=<temp_pod.txt
if not "!PROMETHEUS_POD!"=="" (
    start /B kubectl port-forward pod/!PROMETHEUS_POD! 9090:9090 -n %NAMESPACE%
    echo Port-forward started for prometheus on port 9090
) else (
    echo No pod found for prometheus
)

echo Setting up port-forward for grafana...
kubectl get pods -l app=grafana -n %NAMESPACE% -o jsonpath="{.items[0].metadata.name}" > temp_pod.txt 2>nul
set /p GRAFANA_POD=<temp_pod.txt
if not "!GRAFANA_POD!"=="" (
    start /B kubectl port-forward pod/!GRAFANA_POD! 3000:3000 -n %NAMESPACE%
    echo Port-forward started for grafana on port 3000
) else (
    echo No pod found for grafana
)

echo Setting up port-forward for otel-collector...
kubectl get pods -l app=otel-collector -n %NAMESPACE% -o jsonpath="{.items[0].metadata.name}" > temp_pod.txt 2>nul
set /p OTEL_POD=<temp_pod.txt
if not "!OTEL_POD!"=="" (
    start /B kubectl port-forward pod/!OTEL_POD! 9464:9464 -n %NAMESPACE%
    echo Port-forward started for otel-collector on port 9464
) else (
    echo No pod found for otel-collector
)

del temp_pod.txt >nul 2>&1

timeout /t 3 >nul

timeout /t 3 >nul

echo.
echo Port forwarding active. Access services at:
echo   - Service A: http://localhost:8080
echo   - Service B: http://localhost:8081
echo   - Prometheus: http://localhost:9090
echo   - Grafana: http://localhost:3000
echo   - OTel Collector Metrics: http://localhost:9464/metrics
echo.
echo Port forwarding running in background
echo To stop: scripts\stop-port-forward.bat
echo To check status: scripts\status-port-forward.bat