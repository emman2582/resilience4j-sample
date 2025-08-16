@echo off
REM Grafana Dashboard Loader Script for Windows

set GRAFANA_URL=%1
set GRAFANA_USER=%2
set GRAFANA_PASS=%3
set ENVIRONMENT=%4

if "%GRAFANA_URL%"=="" set GRAFANA_URL=http://localhost:3000
if "%GRAFANA_USER%"=="" set GRAFANA_USER=admin
if "%GRAFANA_PASS%"=="" set GRAFANA_PASS=admin
if "%ENVIRONMENT%"=="" set ENVIRONMENT=local

echo 📊 Loading Grafana dashboards...
echo URL: %GRAFANA_URL%
echo Environment: %ENVIRONMENT%

REM Wait for Grafana to be ready
echo ⏳ Waiting for Grafana to be ready...
for /L %%i in (1,1,30) do (
    curl -s "%GRAFANA_URL%/api/health" >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✅ Grafana is ready
        goto :ready
    )
    echo Waiting... (%%i/30)
    timeout /t 5 >nul
)

:ready
REM Set up Prometheus data source
echo 🔗 Setting up Prometheus data source...
if "%ENVIRONMENT%"=="local" (
    set PROMETHEUS_URL=http://prometheus:9090
) else (
    set PROMETHEUS_URL=http://prometheus.resilience4j-aws-single:9090
)

echo {"name":"Prometheus","type":"prometheus","url":"%PROMETHEUS_URL%","access":"proxy","isDefault":true} > datasource.json
curl -s -X POST -H "Content-Type: application/json" -u "%GRAFANA_USER%:%GRAFANA_PASS%" -d @datasource.json "%GRAFANA_URL%/api/datasources" >nul
del datasource.json

REM Load dashboard files
echo 📈 Loading enhanced dashboard...
call :load_dashboard grafana-dashboard-enhanced.json

echo 📈 Loading golden metrics dashboard...
call :load_dashboard grafana-dashboard-golden-metrics.json

echo ✅ Dashboard loading completed!
echo 🌐 Access Grafana at: %GRAFANA_URL%
goto :eof

:load_dashboard
set dashboard_file=%1
echo Loading dashboard: %dashboard_file%

REM Create payload with dashboard content
powershell -Command "$dashboard = Get-Content '%dashboard_file%' | ConvertFrom-Json; $payload = @{dashboard=$dashboard; overwrite=$true; inputs=@(); folderId=0} | ConvertTo-Json -Depth 100; $payload | Out-File -Encoding UTF8 payload.json"

curl -s -X POST -H "Content-Type: application/json" -u "%GRAFANA_USER%:%GRAFANA_PASS%" -d @payload.json "%GRAFANA_URL%/api/dashboards/db" >response.json

findstr /C:"success" response.json >nul
if !errorlevel! equ 0 (
    echo ✅ Dashboard loaded: %dashboard_file%
) else (
    echo ❌ Failed to load dashboard: %dashboard_file%
    type response.json
)

del payload.json response.json 2>nul
goto :eof