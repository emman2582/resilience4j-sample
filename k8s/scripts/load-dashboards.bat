@echo off
setlocal

set NAMESPACE=%1
if "%NAMESPACE%"=="" set NAMESPACE=resilience4j-local

set GRAFANA_URL=http://localhost:3000
set GRAFANA_USER=admin
set GRAFANA_PASS=admin

echo Loading Grafana dashboards for K8s deployment...
echo Namespace: %NAMESPACE%

echo Checking Grafana accessibility...
curl -s "%GRAFANA_URL%/api/health" >nul 2>&1
if %errorlevel% neq 0 (
    echo Grafana not accessible at %GRAFANA_URL%
    echo Make sure port forwarding is active: scripts\port-forward.bat
    exit /b 1
)

echo Grafana is accessible

echo Setting up Prometheus datasource...
curl -s -X POST -H "Content-Type: application/json" -u "%GRAFANA_USER%:%GRAFANA_PASS%" -d "{\"name\":\"Prometheus\",\"type\":\"prometheus\",\"url\":\"http://prometheus:9090\",\"access\":\"proxy\",\"isDefault\":true}" "%GRAFANA_URL%/api/datasources" >nul 2>&1

echo Prometheus datasource configured

timeout /t 2 >nul

echo Loading dashboards...
if exist "scripts\manual-import.bat" (
    call scripts\manual-import.bat
) else (
    echo Manual import script not found
)

echo.
echo Dashboard loading completed!
echo.
echo Access Grafana at: %GRAFANA_URL%
echo Login: admin/admin
echo Available dashboards:
echo   - Enhanced Resilience4j Dashboard
echo   - Golden Metrics Dashboard