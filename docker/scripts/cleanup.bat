@echo off
REM Docker Compose Cleanup Script for Windows

echo 🧹 Cleaning up Docker Compose deployment...

REM Stop and remove containers, networks, volumes
docker compose down --volumes --remove-orphans

REM Clean up Docker Swarm if active
docker info | findstr "Swarm: active" >nul
if %errorlevel% == 0 (
    echo 🔄 Cleaning up Docker Swarm...
    docker stack rm r4j-stack 2>nul
    timeout /t 10 /nobreak >nul
)

REM Force remove any remaining containers using our images
echo 🛑 Removing containers...

REM Remove by ancestor (image)
for /f %%i in ('docker ps -a --filter "ancestor=r4j-sample-service-a:0.1.0" -q 2^>nul') do docker rm -f %%i 2>nul
for /f %%i in ('docker ps -a --filter "ancestor=r4j-sample-service-b:0.1.0" -q 2^>nul') do docker rm -f %%i 2>nul

REM Remove by container name patterns
for /f %%i in ('docker ps -a --filter "name=service-a" -q 2^>nul') do docker rm -f %%i 2>nul
for /f %%i in ('docker ps -a --filter "name=service-b" -q 2^>nul') do docker rm -f %%i 2>nul
for /f %%i in ('docker ps -a --filter "name=prometheus" -q 2^>nul') do docker rm -f %%i 2>nul
for /f %%i in ('docker ps -a --filter "name=grafana" -q 2^>nul') do docker rm -f %%i 2>nul
for /f %%i in ('docker ps -a --filter "name=otel-collector" -q 2^>nul') do docker rm -f %%i 2>nul

REM Remove containers from docker-compose project
for /f %%i in ('docker ps -a --filter "label=com.docker.compose.project=docker" -q 2^>nul') do docker rm -f %%i 2>nul

REM Remove Docker images
echo 🗑️ Removing Docker images...
docker rmi r4j-sample-service-a:0.1.0 -f 2>nul
docker rmi r4j-sample-service-b:0.1.0 -f 2>nul

REM Remove monitoring stack images if they exist
docker rmi prom/prometheus:v2.45.0 -f 2>nul
docker rmi grafana/grafana:10.0.0 -f 2>nul
docker rmi otel/opentelemetry-collector-contrib:0.91.0 -f 2>nul

REM Clean up dangling images and volumes
docker image prune -f
docker volume prune -f

echo ✅ Docker cleanup completed!