#!/bin/bash
# Thanos Promptology Deployment Script

set -e

echo "=== THANOS PROMPTOLOGY DEPLOYMENT ==="

ENVIRONMENT=${1:-staging}
echo "📦 Deploying to: $ENVIRONMENT"

# Build all apps
echo "🔨 Building applications..."
pnpm build

# Run tests
echo "✅ Running tests..."
pnpm test

# Push database migrations
echo "🗄️  Deploying database migrations..."
pnpm db:push

# Setup environment
if [ "$ENVIRONMENT" = "production" ]; then
    echo "🚀 Deploying to production..."
    # Deploy frontend to Vercel/Netlify
    vercel --prod

    # Deploy backend to Railway/Heroku
    railway up

elif [ "$ENVIRONMENT" = "staging" ]; then
    echo "🚀 Deploying to staging..."
    vercel --scope=thanos
    railway up --environment staging
fi

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo "Frontend: https://app.thanos.dev"
echo "API: https://api.thanos.dev"
