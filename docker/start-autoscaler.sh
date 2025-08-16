#!/bin/bash

# Start Docker Autoscaler

echo "🤖 Starting Docker Autoscaler..."

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is required for autoscaler"
    exit 1
fi

# Install required Python packages
echo "📦 Installing Python dependencies..."
pip3 install requests

# Check if Docker Swarm is active
if ! docker info | grep -q "Swarm: active"; then
    echo "❌ Docker Swarm is not active. Run ./setup-swarm.sh first"
    exit 1
fi

# Start autoscaler
echo "🚀 Starting autoscaler..."
python3 autoscaler.py