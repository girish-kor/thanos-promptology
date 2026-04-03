# UNIT 5 — DEPLOYMENT & CI/CD AUTOMATION SCRIPTS

---

## 5.1 GitHub Actions — Full Stack CI/CD Pipeline

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: "20"
  PNPM_VERSION: "9"

jobs:
  # ─── LINT + TYPECHECK ─────────────────────────────────
  lint:
    name: Lint & Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
        with: { version: "${{ env.PNPM_VERSION }}" }
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: "pnpm"
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm typecheck

  # ─── TEST ─────────────────────────────────────────────
  test:
    name: Unit Tests
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports: ["5432:5432"]
      redis:
        image: redis:7-alpine
        ports: ["6379:6379"]
    env:
      DATABASE_URL: postgresql://test:test@localhost:5432/test_db
      REDIS_URL: redis://localhost:6379
      JWT_SECRET: test_secret
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
        with: { version: "${{ env.PNPM_VERSION }}" }
      - uses: actions/setup-node@v4
        with: { node-version: "${{ env.NODE_VERSION }}", cache: "pnpm" }
      - run: pnpm install --frozen-lockfile
      - run: pnpm --filter api db:push
      - run: pnpm test --coverage
      - uses: codecov/codecov-action@v4
        with: { token: "${{ secrets.CODECOV_TOKEN }}" }

  # ─── BUILD ────────────────────────────────────────────
  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
        with: { version: "${{ env.PNPM_VERSION }}" }
      - uses: actions/setup-node@v4
        with: { node-version: "${{ env.NODE_VERSION }}", cache: "pnpm" }
      - run: pnpm install --frozen-lockfile
      - run: pnpm build
      - uses: actions/upload-artifact@v4
        with:
          name: build-artifacts
          path: |
            apps/web/.next
            apps/api/dist

  # ─── DEPLOY STAGING ───────────────────────────────────
  deploy-staging:
    name: Deploy Staging
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop'
    environment: staging
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with: { name: build-artifacts }
      - name: Deploy to Vercel (Staging)
        run: |
          npx vercel --token ${{ secrets.VERCEL_TOKEN }} \
            --scope ${{ secrets.VERCEL_TEAM_ID }} \
            --yes

  # ─── DEPLOY PRODUCTION ────────────────────────────────
  deploy-production:
    name: Deploy Production
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with: { name: build-artifacts }
      - name: Deploy Frontend to Vercel
        run: |
          npx vercel --token ${{ secrets.VERCEL_TOKEN }} \
            --prod \
            --scope ${{ secrets.VERCEL_TEAM_ID }} \
            --yes
      - name: Deploy Backend to Railway
        run: |
          npm install -g @railway/cli
          railway up --service api
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
      - name: Run DB Migrations
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

---

## 5.2 Docker Multi-Stage Build

```dockerfile
# apps/api/Dockerfile
FROM node:20-alpine AS base
RUN npm install -g pnpm
WORKDIR /app

# Dependencies
FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/api/package.json ./apps/api/
COPY packages/*/package.json ./packages/*/
RUN pnpm install --frozen-lockfile --prod

# Builder
FROM base AS builder
COPY . .
COPY --from=deps /app/node_modules ./node_modules
RUN pnpm --filter api build
RUN pnpm dlx prisma generate

# Runner
FROM node:20-alpine AS runner
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder --chown=appuser:appgroup /app/apps/api/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/apps/api/prisma ./prisma
COPY --from=deps --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder /app/apps/api/package.json ./

USER appuser
EXPOSE 3001
CMD ["node", "dist/index.js"]
```

```dockerfile
# apps/web/Dockerfile
FROM node:20-alpine AS base
RUN npm install -g pnpm

FROM base AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/web/package.json ./apps/web/
RUN pnpm install --frozen-lockfile

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm --filter web build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup -S nodejs && adduser -S nextjs -G nodejs
COPY --from=builder /app/apps/web/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT=3000
CMD ["node", "server.js"]
```

```bash
# Build and push to registry
docker build -t myapp/api:latest -f apps/api/Dockerfile .
docker build -t myapp/web:latest -f apps/web/Dockerfile .

docker push myapp/api:latest
docker push myapp/web:latest
```

---

## 5.3 Vercel Config

```json
// apps/web/vercel.json
{
  "framework": "nextjs",
  "buildCommand": "pnpm build",
  "devCommand": "pnpm dev",
  "installCommand": "pnpm install",
  "regions": ["iad1"],
  "env": {
    "NEXT_PUBLIC_API_URL": "@api_url"
  },
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
      ]
    }
  ],
  "rewrites": [
    { "source": "/api/:path*", "destination": "https://api.yourdomain.com/api/:path*" }
  ]
}
```

---

## 5.4 Railway Deployment Script

```bash
#!/bin/bash
# scripts/deploy-railway.sh

set -e

echo "🚂 Deploying to Railway..."

# Install Railway CLI
npm install -g @railway/cli

# Login (use token in CI)
railway login --browserless

# Deploy API service
railway up \
  --service api \
  --detach

# Run migrations
railway run --service api npx prisma migrate deploy

# Check health
sleep 15
HEALTH=$(railway run --service api curl -s http://localhost:3001/health | jq -r '.status')
if [ "$HEALTH" != "ok" ]; then
  echo "❌ Health check failed"
  exit 1
fi

echo "✅ Railway deployment successful"
```

---

## 5.5 Zero-Downtime Deploy Script

```bash
#!/bin/bash
# scripts/deploy-zero-downtime.sh

set -euo pipefail

CONTAINER_NAME="myapp-api"
NEW_IMAGE="myapp/api:$1"
PORT_A=3001
PORT_B=3002

echo "🚀 Zero-downtime deploy: $NEW_IMAGE"

# Pull new image
docker pull $NEW_IMAGE

# Start new container on alternate port
docker run -d \
  --name ${CONTAINER_NAME}-new \
  -p ${PORT_B}:3001 \
  --env-file .env.production \
  $NEW_IMAGE

# Wait for health check
echo "Waiting for new container..."
for i in $(seq 1 30); do
  if curl -sf "http://localhost:${PORT_B}/health" > /dev/null; then
    echo "✅ New container healthy"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Health check timeout"
    docker rm -f ${CONTAINER_NAME}-new
    exit 1
  fi
  sleep 2
done

# Switch nginx upstream
sed -i "s/localhost:${PORT_A}/localhost:${PORT_B}/" /etc/nginx/conf.d/app.conf
nginx -s reload

# Stop old container
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true
docker rename ${CONTAINER_NAME}-new $CONTAINER_NAME

# Switch nginx back to primary port
docker run -d \
  --name ${CONTAINER_NAME} \
  -p ${PORT_A}:3001 \
  --env-file .env.production \
  $NEW_IMAGE

echo "✅ Deploy complete"
```

---

## 5.6 Environment Secret Management

```bash
# Sync secrets to Vercel
vercel env add DATABASE_URL production
vercel env add JWT_SECRET production
vercel env add STRIPE_SECRET_KEY production

# Pull env from Vercel to local
vercel env pull .env.local

# GitHub secrets via CLI
gh secret set DATABASE_URL < .env.production
gh secret set JWT_SECRET --body "$(openssl rand -hex 32)"

# Generate secure secrets
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
openssl rand -base64 32
```

---

## 5.7 Database Migration in CI

```yaml
# .github/workflows/migrate.yml
name: Database Migration
on:
  workflow_run:
    workflows: ["CI/CD Pipeline"]
    branches: [main]
    types: [completed]

jobs:
  migrate:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
      - run: pnpm install --frozen-lockfile
      - name: Run Prisma Migrations
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
      - name: Verify Migration
        run: npx prisma migrate status
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

---

## 5.8 Rollback Script

```bash
#!/bin/bash
# scripts/rollback.sh

set -e

CONTAINER_NAME="myapp-api"
PREVIOUS_IMAGE=$(docker inspect $CONTAINER_NAME --format '{{.Config.Image}}' 2>/dev/null)
TARGET_IMAGE=${1:-"myapp/api:previous"}

echo "⚠️  Rolling back to: $TARGET_IMAGE"

docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME
docker run -d \
  --name $CONTAINER_NAME \
  -p 3001:3001 \
  --env-file .env.production \
  --restart unless-stopped \
  $TARGET_IMAGE

# Verify
sleep 5
curl -sf http://localhost:3001/health || { echo "❌ Rollback failed"; exit 1; }
echo "✅ Rollback successful to $TARGET_IMAGE"
```
