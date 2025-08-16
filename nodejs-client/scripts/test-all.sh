#!/bin/bash

# Comprehensive test script for NodeJS client
# Tests all endpoints and patterns

echo "🧪 Running comprehensive NodeJS client tests..."

# Check if services are running
echo "🔍 Checking service availability..."
SERVICE_A_URL=${SERVICE_A_URL:-http://localhost:8080}

if ! curl -s "$SERVICE_A_URL/actuator/health" > /dev/null; then
    echo "❌ Service A not available at $SERVICE_A_URL"
    echo "   Please start services first:"
    echo "   gradle :service-b:bootRun && gradle :service-a:bootRun"
    exit 1
fi

echo "✅ Service A is available"

# Run unit tests
echo "🔬 Running unit tests..."
npm test

# Run basic client test
echo "🚀 Running basic client test..."
npm start

# Run performance tests
echo "📊 Running performance tests..."
npm run test:performance

echo "✅ All tests completed successfully!"