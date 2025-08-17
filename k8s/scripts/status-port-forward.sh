#!/bin/bash

# Check port forwarding daemon status

echo "📊 Port Forwarding Status"
echo "========================="

# Check if daemon PID file exists
if [ -f "/tmp/port-forward-daemon.pid" ]; then
    DAEMON_PID=$(cat /tmp/port-forward-daemon.pid)
    if ps -p $DAEMON_PID > /dev/null 2>&1; then
        echo "✅ Daemon running (PID: $DAEMON_PID)"
    else
        echo "❌ Daemon PID file exists but process not running"
        rm -f /tmp/port-forward-daemon.pid
    fi
else
    echo "⚠️  No daemon PID file found"
fi

echo ""
echo "🔍 Active kubectl port-forward processes:"
ps aux | grep "kubectl port-forward" | grep -v grep || echo "None found"

echo ""
echo "📊 Port status:"
for port in 8080 8081 9090 3000 9464; do
    if netstat -an 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo "  Port $port: ✅ In use"
    else
        echo "  Port $port: ❌ Available"
    fi
done

echo ""
echo "🌐 If ports are active, access services at:"
echo "  - Service A: http://localhost:8080"
echo "  - Service B: http://localhost:8081"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3000"
echo "  - OTel Collector: http://localhost:9464/metrics"