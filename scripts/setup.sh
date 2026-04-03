#!/bin/bash
# Thanos Promptology Setup Script

echo "=== THANOS PROMPTOLOGY SETUP ==="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
















































echo ""echo "4. Run 'pnpm dev' to start development"echo "3. Run 'pnpm seed' to populate sample data"echo "2. Run 'pnpm db:push' to sync database schema"echo "1. Update .env.local with your configuration"echo "Next steps:"echo ""echo "=== SETUP COMPLETE ==="echo ""fi    echo "⚠️  Docker not found. Skip this step if services are running."else    echo "✅ Docker services started"    docker-compose up -dif command -v docker-compose &> /dev/null; thenecho "🐳 Starting Docker containers..."# Start Docker servicesfi    echo "⚠️  Update .env.local with your secrets"    cp .env.example .env.local    echo "📝 Creating .env.local from .env.example..."if [ ! -f .env.local ]; then# Create .env.local if it doesn't existpnpm --filter database generateecho "🗄️  Generating Prisma client..."# Generate Prisma clientpnpm installecho "📥 Installing dependencies..."# Install dependenciesecho "✅ pnpm $(pnpm -v) ready"fi    npm install -g pnpm    echo "📦 Installing pnpm..."if ! command -v pnpm &> /dev/null; then# Check if pnpm is installedecho "✅ Node.js $(node -v) detected"fi    exit 1    echo "Please install Node.js from https://nodejs.org/"
