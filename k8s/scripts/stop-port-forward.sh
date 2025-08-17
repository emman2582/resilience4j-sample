#!/bin/bash

# Stop all port forwarding processes

echo "🛑 Stopping all port forwarding processes..."

# Kill daemon if PID file exists
if [ -f "/tmp/port-forward-daemon.pid" ]; then
    DAEMON_PID=$(cat /tmp/port-forward-daemon.pid)
    echo "🔄 Stopping daemon (PID: $DAEMON_PID)..."
    kill $DAEMON_PID 2>/dev/null || true
    rm -f /tmp/port-forward-daemon.pid
fi

# Kill kubectl port-forward processes
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 2

# Force kill any remaining processes
pkill -9 -f "kubectl port-forward" 2>/dev/null || true
sleep 1

# Check if any processes are still running
REMAINING=$(ps aux | grep "kubectl port-forward" | grep -v grep | wc -l)

if [ $REMAINING -eq 0 ]; then
    echo "✅ All port forwarding processes stopped"
else
    echo "⚠️  $REMAINING port forwarding processes may still be running"
    echo "Manual cleanup may be required"
fi

# Show port status
echo ""
echo "📊 Port status:"
for port in 8080 8081 9090 3000 9464; do
    if netstat -an 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo "  Port $port: In use"
    else
        echo "  Port $port: Available"
    fi
done