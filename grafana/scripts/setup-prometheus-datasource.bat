@echo off
REM Prometheus Datasource Setup Script for Grafana (Windows)

set GRAFANA_URL=%1
set GRAFANA_USER=%2
set GRAFANA_PASS=%3
set ENVIRONMENT=%4

if "%GRAFANA_URL%"=="" set GRAFANA_URL=http://localhost:3000
if "%GRAFANA_USER%"=="" set GRAFANA_USER=admin
if "%GRAFANA_PASS%"=="" set GRAFANA_PASS=admin
if "%ENVIRONMENT%"=="" set ENVIRONMENT=local

echo 🔗 Setting up Prometheus datasource in Grafana...
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
    timeout /t 2 >nul
)

:ready
REM Set Prometheus URL based on environment
if "%ENVIRONMENT%"=="local" (
    set PROMETHEUS_URL=http://prometheus:9090
) else if "%ENVIRONMENT%"=="aws-multi" (
    set PROMETHEUS_URL=http://prometheus.resilience4j-aws-multi:9090
) else (
    set PROMETHEUS_URL=http://prometheus.resilience4j-aws-single:9090
)

echo 📊 Prometheus URL: %PROMETHEUS_URL%

REM Create datasource payload
echo { > datasource.json
echo   "name": "Prometheus", >> datasource.json
echo   "type": "prometheus", >> datasource.json
echo   "url": "%PROMETHEUS_URL%", >> datasource.json
echo   "access": "proxy", >> datasource.json
echo   "isDefault": true, >> datasource.json
echo   "basicAuth": false >> datasource.json
echo } >> datasource.json

REM Create or update datasource
curl -s -X POST -H "Content-Type: application/json" -u "%GRAFANA_USER%:%GRAFANA_PASS%" -d @datasource.json "%GRAFANA_URL%/api/datasources" > response.json

REM Check response
findstr /C:"id" response.json >nul
if %errorlevel% equ 0 (
    echo ✅ Prometheus datasource configured successfully
) else (
    echo ❌ Failed to configure Prometheus datasource
    type response.json
    del datasource.json response.json
    exit /b 1
)

del datasource.json response.json
echo 🎯 Prometheus datasource setup completed!