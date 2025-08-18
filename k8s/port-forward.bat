@echo off
REM Port Forward Script for Windows

set NAMESPACE=%1
if "%NAMESPACE%"=="" set NAMESPACE=resilience4j-local

echo 🔗 Setting up port forwarding for %NAMESPACE%...

REM Kill existing port forwards
echo 🧹 Cleaning up existing port forwards...
taskkill /F /IM kubectl.exe 2>nul
timeout /t 2 >nul

REM Check if pods are ready
echo ⏳ Waiting for pods to be ready...
kubectl wait --for=condition=ready pod -l app=service-a -n %NAMESPACE% --timeout=60s
kubectl wait --for=condition=ready pod -l app=grafana -n %NAMESPACE% --timeout=60s
kubectl wait --for=condition=ready pod -l app=prometheus -n %NAMESPACE% --timeout=60s

REM Find available ports
set SERVICE_A_PORT=8080
set GRAFANA_PORT=3000
set PROMETHEUS_PORT=9090

REM Check if ports are in use and increment if needed
:check_service_a_port
netstat -an | findstr ":%SERVICE_A_PORT% " >nul
if %errorlevel%==0 (
    set /a SERVICE_A_PORT+=1
    goto check_service_a_port
)

:check_grafana_port
netstat -an | findstr ":%GRAFANA_PORT% " >nul
if %errorlevel%==0 (
    set /a GRAFANA_PORT+=1
    goto check_grafana_port
)

:check_prometheus_port
netstat -an | findstr ":%PROMETHEUS_PORT% " >nul
if %errorlevel%==0 (
    set /a PROMETHEUS_PORT+=1
    goto check_prometheus_port
)

echo 📋 Using ports:
echo   Service A: %SERVICE_A_PORT%
echo   Grafana: %GRAFANA_PORT%
echo   Prometheus: %PROMETHEUS_PORT%

REM Start port forwards
echo 🔗 Starting port forwards...
start /B kubectl port-forward svc/service-a %SERVICE_A_PORT%:8080 -n %NAMESPACE%
start /B kubectl port-forward svc/grafana %GRAFANA_PORT%:3000 -n %NAMESPACE%
start /B kubectl port-forward svc/prometheus %PROMETHEUS_PORT%:9090 -n %NAMESPACE%

REM Wait for connections to be ready
timeout /t 5 >nul

echo.
echo 🎯 Access Points:
echo   Service A: http://localhost:%SERVICE_A_PORT%
echo   Grafana: http://localhost:%GRAFANA_PORT% (admin/admin)
echo   Prometheus: http://localhost:%PROMETHEUS_PORT%
echo.
echo 🛑 To stop port forwarding:
echo   taskkill /F /IM kubectl.exe