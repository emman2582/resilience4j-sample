#!/bin/bash

# Grafana Cleanup Script

echo "🧹 Cleaning up Grafana resources..."

# Stop port forwarding
pkill -f "kubectl port-forward.*grafana" || true

# Clean up temporary files
rm -f datasource.json || true
rm -f payload.json || true
rm -f response.json || true

echo "✅ Grafana cleanup completed!"