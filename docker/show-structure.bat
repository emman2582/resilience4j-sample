@echo off
REM Display Docker directory structure

echo 🐳 Docker Directory Structure
echo =============================
echo.

echo 📁 docker/
echo ├── 📁 configs/
echo │   ├── prometheus.yml
echo │   ├── otel-collector-config.yml
echo │   ├── nginx.conf
echo │   └── custom-values.yaml
echo ├── 📁 dashboards/
echo │   ├── grafana-dashboard.json
echo │   ├── grafana-dashboard-enhanced.json
echo │   ├── grafana-dashboard-golden-metrics.json
echo │   └── grafana-dashboard-updated.json
echo ├── 📁 scripts/
echo │   ├── 📁 testing/
echo │   │   ├── test-docker-compose.sh
echo │   │   ├── test-bulkhead-comprehensive.sh
echo │   │   ├── test-circuit-breaker.sh
echo │   │   ├── test-resilience.sh
echo │   │   └── check-bulkhead-config.sh
echo │   └── 📁 maintenance/
echo │       ├── cleanup.sh / cleanup.bat
echo │       ├── diagnose-metrics.sh
echo │       ├── fix-metrics.sh
echo │       ├── force-cleanup.sh
echo │       └── restart-service-a.sh
echo ├── 📁 swarm/
echo │   ├── docker-compose-swarm.yml
echo │   ├── setup-swarm.sh
echo │   ├── start-autoscaler.sh
echo │   ├── test-scaling.sh
echo │   └── autoscaler.py
echo ├── build.sh / build.bat
echo ├── docker-compose.yml
echo ├── .gitignore
echo └── README.md

echo.
echo 📋 Quick Commands:
echo ==================
echo 🏗️  Build:           .\build.bat
echo 🚀 Start:           docker compose up -d
echo 🧪 Test:            .\scripts\testing\test-docker-compose.sh
echo 📊 Metrics:         http://localhost:9090 (Prometheus)
echo 📈 Dashboards:      http://localhost:3000 (Grafana)
echo 🧹 Cleanup:         .\scripts\maintenance\cleanup.bat
echo.
echo 📖 For detailed instructions, see README.md