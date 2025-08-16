#!/bin/bash

# Test Lambda containers locally using Docker Compose

echo "🧪 Testing Lambda containers locally..."

# Start containers
echo "🚀 Starting containers..."
docker-compose up -d

# Wait for containers to be ready
echo "⏳ Waiting for containers to be ready..."
sleep 10

# Test Service A endpoints
echo "🔍 Testing Service A endpoints..."

echo "Testing health endpoint..."
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{"httpMethod":"GET","path":"/health"}'

echo -e "\nTesting OK endpoint..."
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{"httpMethod":"GET","path":"/api/a/ok"}'

echo -e "\nTesting flaky endpoint..."
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{"httpMethod":"GET","path":"/api/a/flaky","queryStringParameters":{"failRate":"30"}}'

# Test Service B endpoints
echo -e "\n🔍 Testing Service B endpoints..."

echo "Testing Service B health..."
curl -X POST "http://localhost:9001/2015-03-31/functions/function/invocations" \
  -d '{"httpMethod":"GET","path":"/health"}'

echo -e "\nTesting Service B OK..."
curl -X POST "http://localhost:9001/2015-03-31/functions/function/invocations" \
  -d '{"httpMethod":"GET","path":"/ok"}'

echo -e "\n✅ Local container testing completed!"
echo "🛑 Stop containers with: docker-compose down"