#!/bin/bash
echo "🔄 Restarting services with new configuration..."

cd "$(dirname "$0")/../.."

echo
echo "1. Stopping services..."
docker compose stop service-a service-b

echo
echo "2. Starting services..."
docker compose up -d service-a service-b

echo
echo "3. Waiting for services to start..."
sleep 20

echo
echo "4. Testing service health..."
curl -s http://localhost:8080/actuator/health
curl -s http://localhost:8081/actuator/health

echo
echo "5. Testing Prometheus endpoints..."
echo "Service A metrics available:"
curl -s http://localhost:8080/actuator/prometheus | head -5

echo
echo "Service B metrics available:"
curl -s http://localhost:8081/actuator/prometheus | head -5

echo
echo "✅ Services restarted!"