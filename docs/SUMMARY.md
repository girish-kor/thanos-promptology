# SUMMARY — CONSOLIDATED THANOS PROMPTS & SCRIPTS

> Copy-paste ready. No setup required beyond the README.

---

## MASTER THANOS PROMPT (Use This First)

```
You are a senior full stack engineer with 10+ years experience.
Respond ONLY with production-ready code. No explanations. No placeholders. No TODOs.

STACK: [YOUR STACK]
TASK: [YOUR TASK]
CONSTRAINTS: [YOUR CONSTRAINTS]

OUTPUT FORMAT:
For each file, start with:
// FILE: path/to/file.ts
[complete file contents]
---
```

---

## QUICK-FIRE PROMPTS BY CATEGORY

### 🏗️ Scaffold

```bash
# Next.js + Prisma + Auth + shadcn (30 seconds)
npx create-next-app@latest myapp --typescript --tailwind --app --src-dir --import-alias "@/*" && cd myapp && pnpm add prisma @prisma/client next-auth zod @tanstack/react-query zustand react-hook-form @hookform/resolvers lucide-react && pnpm dlx shadcn@latest init -d && pnpm dlx prisma init

# NestJS API
npm i -g @nestjs/cli && nest new myapi --strict --package-manager pnpm

# Turborepo monorepo
npx create-turbo@latest mymonorepo --package-manager pnpm

# T3 Stack
pnpm create t3-app@latest myapp --CI --trpc --prisma --nextAuth --tailwind --appRouter --dbProvider postgresql

# Local services
docker-compose up -d  # postgres + redis + mailhog
```

---

### 🤖 Prompt: Generate CRUD Feature

```
Stack: Next.js 14 + TypeScript + Prisma + PostgreSQL
Resource: [NAME] with fields: [field:type, ...]
Generate: Prisma model, Zod schemas, API route, Server action, React component, custom hook
Pattern: Service layer, thin controller, optimistic UI updates
No TODOs. No placeholders. Complete files only.
```

---

### 🔐 Prompt: Add Auth to Existing App

```
Add complete authentication to this Next.js app.
Current stack: [describe]
Auth needed: email/password + Google OAuth
Generate:
- NextAuth config (app/api/auth/[...nextauth]/route.ts)
- Prisma User + Account + Session models
- Login page, Register page, middleware.ts
- useSession hook usage examples
- Protected route pattern
```

---

### 🚀 Prompt: Generate CI/CD Pipeline

```
Generate GitHub Actions CI/CD pipeline.
Stack: [frontend framework] + [backend framework]
Deploy: Frontend → Vercel, Backend → Railway
Tests: [Jest/Vitest], E2E: [Playwright]
Generate: .github/workflows/ci-cd.yml
Include: lint, typecheck, unit tests, build, deploy staging (develop branch), deploy production (main branch)
```

---

### ⚡ Prompt: Fix Performance Issues

```
Audit and fix performance in this code: [paste code]
Stack: [stack]
Target: API < 200ms p95, Lighthouse > 90
Fix: N+1 queries, missing indexes, missing caching, bundle size, React re-renders
Show: Before → After for each fix. Commands to verify improvements.
```

---

### 🧪 Prompt: Generate Test Suite

```
Generate complete test suite for: [paste code or describe function]
Stack: Vitest + Testing Library / Supertest
Cover: happy path, edge cases, error cases
Mock: all external dependencies
Target: >90% coverage
Output: Complete .test.ts file
```

---

### 🔴 Prompt: Add Real-Time Features

```
Add real-time to this app: [describe feature]
Stack: Socket.io + Redis adapter + React
Generate: socket server setup, auth middleware, React hook, UI component
Events: [list events]
Scale: multi-server ready (Redis adapter)
```

---

## SCRIPTS — COPY AND RUN

```bash
# Generate secure secrets
node -e "console.log('JWT_SECRET=' + require('crypto').randomBytes(32).toString('hex'))"
node -e "console.log('NEXTAUTH_SECRET=' + require('crypto').randomBytes(32).toString('hex'))"

# Database operations
npx prisma generate && npx prisma migrate dev --name init
npx prisma studio
npx tsx scripts/seed.ts

# Docker dev environment
docker-compose up -d postgres redis mailhog
docker-compose logs -f api

# Deployment
vercel --prod
railway up --service api
npx prisma migrate deploy

# Testing
pnpm test --coverage
pnpm test:e2e
k6 run scripts/load-test.js

# Bundle analysis
ANALYZE=true pnpm build

# Security audit
npm audit --audit-level=high
npx snyk test
```

---

## THE THANOS PROMPT FORMULA (REFERENCE CARD)

```
T — Task:        What must be built (feature name + behavior)
H — Handle:      Tech stack (framework + DB + auth + deploy target)
A — Assumptions: Existing code context, constraints, what NOT to change
N — Needs:       Output format (which files, folder structure)
O — Optimize:    Performance target, security requirement, scale goal
S — Style:       Code conventions, patterns, naming (TypeScript strict, no any)
```

### Strength Levels

| Level | Use When | Prompt Length |
|-------|----------|---------------|
| Quick | Small component or utility | 3-5 lines |
| Standard | Full feature (route + component + hook) | 10-20 lines |
| Thanos | End-to-end system | 30-50 lines |
| Infinity | Full app blueprint | UNIT10 templates |

---

## ENVIRONMENT VARIABLES CHECKLIST

```env
# Core (always needed)
DATABASE_URL=
REDIS_URL=
JWT_SECRET=                    # openssl rand -hex 32
NEXTAUTH_SECRET=               # openssl rand -base64 32
NODE_ENV=

# Frontend
NEXT_PUBLIC_APP_URL=
NEXT_PUBLIC_API_URL=

# Auth
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GITHUB_ID=
GITHUB_SECRET=

# Payments
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
STRIPE_PUBLISHABLE_KEY=        # NEXT_PUBLIC_

# Storage
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

# Email
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASS=
FROM_EMAIL=

# AI (if applicable)
OPENAI_API_KEY=

# Monitoring
SENTRY_DSN=
```

---

## DECISION MATRIX

| Need | Use |
|------|-----|
| Full-stack app with auth | Next.js + NextAuth + Prisma |
| API-first backend | NestJS + TypeORM or Express + Prisma |
| Real-time features | Socket.io + Redis adapter |
| Payments | Stripe |
| File storage | Cloudinary (images) or S3 (files) |
| Email | Resend or SendGrid |
| Background jobs | BullMQ + Redis |
| Search | Postgres full-text or Meilisearch |
| Caching | Redis |
| Deploy frontend | Vercel |
| Deploy backend | Railway or Render |
| Deploy full stack | Fly.io or DigitalOcean App Platform |
| Mobile | Expo (React Native) |
| State management | Zustand (simple) / Redux Toolkit (complex) |
| Server state | TanStack Query |
| Forms | React Hook Form + Zod |
| UI components | shadcn/ui + Tailwind |
| Testing | Vitest + Testing Library + Playwright |
| Monorepo | Turborepo |
```
