#!/bin/bash

# NodeJS Client Cleanup Script

echo "🧹 Cleaning up NodeJS client..."

# Stop any running processes
pkill -f "node.*src" || true

# Clean dependencies and cache
echo "📦 Cleaning dependencies..."
rm -rf node_modules || true
rm -f package-lock.json || true

# Clean npm cache
npm cache clean --force || true

# Remove environment file
rm -f .env || true

# Remove test artifacts
rm -rf coverage || true
rm -f *.log || true

echo "✅ NodeJS client cleanup completed!"