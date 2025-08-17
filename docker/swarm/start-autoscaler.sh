#!/bin/bash

# Start Docker Autoscaler

echo "🤖 Starting Docker Autoscaler..."

# Check if Python is available
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    PIP_CMD="pip3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
    PIP_CMD="pip"
else
    echo "❌ Python is required for autoscaler"
    echo "💡 Install Python from: https://www.python.org/downloads/"
    exit 1
fi

echo "🐍 Using Python: $PYTHON_CMD"

# Install required Python packages
echo "📦 Installing Python dependencies..."
$PIP_CMD install requests

# Check if Docker Swarm is active
if ! docker info | grep -q "Swarm: active"; then
    echo "❌ Docker Swarm is not active. Run ./setup-swarm.sh first"
    exit 1
fi

# Start autoscaler
echo "🚀 Starting autoscaler..."
$PYTHON_CMD autoscaler.py