@echo off
setlocal

set GRAFANA_URL=http://localhost:3000
set GRAFANA_USER=admin
set GRAFANA_PASS=admin

echo Importing Enhanced Dashboard...
curl -X POST -H "Content-Type: application/json" -u "%GRAFANA_USER%:%GRAFANA_PASS%" -d @..\docker\dashboards\grafana-dashboard-enhanced.json "%GRAFANA_URL%/api/dashboards/db"

echo.
echo Importing Golden Metrics Dashboard...
curl -X POST -H "Content-Type: application/json" -u "%GRAFANA_USER%:%GRAFANA_PASS%" -d @..\docker\dashboards\grafana-dashboard-golden-metrics.json "%GRAFANA_URL%/api/dashboards/db"

echo.
echo Done! Check Grafana at %GRAFANA_URL%