#!/bin/bash

# Test Docker Scaling

echo "🧪 Testing Docker scaling..."

# Generate load
echo "📈 Generating load to trigger scaling..."
for i in {1..10}; do
    echo "Starting load generator $i..."
    (
        while true; do
            curl -s http://localhost/api/a/ok > /dev/null
            sleep 0.1
        done
    ) &
done

echo "🔍 Monitor scaling with:"
echo "  docker service ls"
echo "  docker service ps r4j-stack_service-a"

# Monitor for 5 minutes
echo "📊 Monitoring for 5 minutes..."
for i in {1..10}; do
    echo "--- Minute $i ---"
    docker service ls | grep service-a
    sleep 30
done

# Stop load generators
echo "🛑 Stopping load generators..."
pkill -f "curl.*localhost"

echo "✅ Scaling test completed!"