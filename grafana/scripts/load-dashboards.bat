@echo off
REM Grafana Dashboard Loader Script (Windows)

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

REM Setup Prometheus datasource first
echo 🔗 Setting up Prometheus datasource...
call setup-prometheus-datasource.bat "%GRAFANA_URL%" "%GRAFANA_USER%" "%GRAFANA_PASS%" "%ENVIRONMENT%"

if %errorlevel% neq 0 (
    echo ❌ Failed to setup Prometheus datasource
    exit /b 1
)

REM Load dashboards from dashboards directory
cd ..\dashboards
if not exist "*.json" (
    echo ⚠️ No dashboard files found in dashboards directory
    exit /b 0
)

set dashboard_count=0
for %%f in (*.json) do (
    echo 📈 Loading dashboard: %%~nf
    
    REM Create dashboard payload (simplified for batch)
    echo { > payload.json
    echo   "dashboard": >> payload.json
    type "%%f" >> payload.json
    echo   , >> payload.json
    echo   "overwrite": true, >> payload.json
    echo   "inputs": [], >> payload.json
    echo   "folderId": 0 >> payload.json
    echo } >> payload.json
    
    REM Load dashboard
    curl -s -X POST -H "Content-Type: application/json" -u "%GRAFANA_USER%:%GRAFANA_PASS%" -d @payload.json "%GRAFANA_URL%/api/dashboards/db" > response.json
    
    findstr /C:"success" response.json >nul
    if %errorlevel% equ 0 (
        echo ✅ Dashboard loaded: %%~nf
    ) else (
        echo ❌ Failed to load dashboard: %%~nf
    )
    
    set /a dashboard_count+=1
    del payload.json response.json
)

echo ✅ Dashboard loading completed!
echo 🌐 Access Grafana at: %GRAFANA_URL%