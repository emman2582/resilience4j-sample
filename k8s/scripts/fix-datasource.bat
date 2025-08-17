@echo off
set GRAFANA_URL=http://localhost:3000
set GRAFANA_USER=admin
set GRAFANA_PASS=admin

echo Fixing Prometheus datasource...
curl -X PUT -H "Content-Type: application/json" -u "%GRAFANA_USER%:%GRAFANA_PASS%" -d "{\"name\":\"Prometheus\",\"type\":\"prometheus\",\"url\":\"http://127.0.0.1:9090\",\"access\":\"proxy\",\"isDefault\":true}" "%GRAFANA_URL%/api/datasources/1"

echo Done!