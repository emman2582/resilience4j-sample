#!/bin/bash

# NodeJS Client Setup Script
# Sets up environment and dependencies

echo "🚀 Setting up NodeJS client..."

# Check Node.js version
NODE_VERSION=$(node --version 2>/dev/null || echo "not found")
if [[ "$NODE_VERSION" == "not found" ]]; then
    echo "❌ Node.js not found. Please install Node.js 18+ first."
    exit 1
fi

echo "📦 Node.js version: $NODE_VERSION"

# Install dependencies
echo "📥 Installing dependencies..."
npm install

# Setup environment file
if [ ! -f ".env" ]; then
    if [ -f "config/.env.example" ]; then
        echo "⚙️  Creating .env file from template..."
        cp config/.env.example .env
        echo "✅ Created .env file. Please edit it for your environment."
    else
        echo "⚠️  .env.example not found, creating basic .env..."
        cat > .env << EOF
# NodeJS Client Configuration
SERVICE_A_URL=http://localhost:8080
NODE_ENV=local
EOF
    fi
else
    echo "✅ .env file already exists"
fi

echo "🧪 Running tests to verify setup..."
npm test

echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Edit .env file for your environment"
echo "   2. Start services: gradle :service-b:bootRun && gradle :service-a:bootRun"
echo "   3. Run client: npm start"
echo "   4. Run performance tests: npm run test:performance"