#!/bin/bash

# Comprehensive Autoscaler Testing Script

echo "🧪 Testing Docker Autoscaler Implementation..."

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check if swarm is active
if ! docker info | grep -q "Swarm: active"; then
    echo "❌ Docker Swarm is not active. Run ./setup-swarm.sh first"
    exit 1
fi

# Check if services are running
if ! docker service ls | grep -q "r4j-stack_service-a"; then
    echo "❌ Service r4j-stack_service-a not found. Deploy stack first"
    exit 1
fi

# Check if Prometheus is accessible
if ! curl -s http://localhost:9090/api/v1/query?query=up >/dev/null; then
    echo "❌ Prometheus not accessible at http://localhost:9090"
    exit 1
fi

echo "✅ Prerequisites met"

# Test 1: Verify current state
echo ""
echo "🔍 Test 1: Current Service State"
echo "Current replicas:"
docker service ls | grep service-a
echo ""

# Test 2: Manual scaling test
echo "🔧 Test 2: Manual Scaling Test"
echo "Scaling to 3 replicas manually..."
docker service scale r4j-stack_service-a=3
sleep 10
docker service ls | grep service-a
echo ""

# Test 3: Load generation for scale-up
echo "📈 Test 3: Load Generation (Scale-Up Test)"
echo "Generating high load to trigger scale-up..."
echo "Target: >70% CPU or >80% Memory"

# Start load generators
for i in {1..5}; do
    echo "Starting load generator $i..."
    (
        while true; do
            curl -s "http://localhost/api/a/slow?delayMs=1000" >/dev/null &
            curl -s "http://localhost/api/a/flaky?failRate=30" >/dev/null &
            sleep 0.1
        done
    ) &
    LOAD_PIDS[$i]=$!
done

echo "🔍 Monitoring scaling behavior for 3 minutes..."
for i in {1..6}; do
    echo "--- Check $i (30s intervals) ---"
    echo "Service status:"
    docker service ls | grep service-a
    
    echo "Prometheus metrics:"
    curl -s "http://localhost:9090/api/v1/query?query=rate(container_cpu_usage_seconds_total[5m])*100" | grep -o '"value":\[[^]]*\]' | head -1
    
    sleep 30
done

# Stop load generators
echo "🛑 Stopping load generators..."
for pid in "${LOAD_PIDS[@]}"; do
    kill $pid 2>/dev/null
done
pkill -f "curl.*localhost" 2>/dev/null

# Test 4: Scale-down test
echo ""
echo "📉 Test 4: Scale-Down Test"
echo "Waiting for scale-down (5 minute cooldown)..."
echo "Monitoring for 6 minutes..."

for i in {1..12}; do
    echo "--- Check $i (30s intervals) ---"
    docker service ls | grep service-a
    sleep 30
done

# Test 5: Autoscaler logs verification
echo ""
echo "📊 Test 5: Autoscaler Behavior Summary"
echo "Expected behavior:"
echo "- Scale up when CPU >70% or Memory >80%"
echo "- Scale down when CPU <35% and Memory <40%"
echo "- Min replicas: 1, Max replicas: 5"
echo "- Scale up cooldown: 60s, Scale down cooldown: 300s"

echo ""
echo "🎯 Testing completed!"
echo "💡 To test autoscaler manually:"
echo "   1. Start autoscaler: ./start-autoscaler.sh"
echo "   2. Generate load: ./test-scaling.sh"
echo "   3. Monitor: docker service ls"