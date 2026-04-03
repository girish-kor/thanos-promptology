# THANOS PROMPT USING PROMPTOLOGY FOR FULL STACK DEVELOPMENT
## Textbook Setup & Prerequisites

---

## Prerequisites Installation Script

```bash
#!/bin/bash
# run: chmod +x setup.sh && ./setup.sh

echo "=== THANOS PROMPTOLOGY SETUP ==="

# Node.js & npm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Package managers
npm install -g pnpm yarn bun

# Global CLI tools
npm install -g \
  create-next-app \
  create-react-app \
  @nestjs/cli \
  @prisma/cli \
  prisma \
  tsx \
  ts-node \
  typescript \
  eslint \
  prettier \
  turbo \
  vercel \
  railway \
  wrangler \
  supabase \
  drizzle-kit

# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Git config
git config --global init.defaultBranch main
git config --global pull.rebase false

echo "=== SETUP COMPLETE ==="
node -v && npm -v && docker --version
```

---

## Master Project Folder Scaffold

```
thanos-promptology/
├── README.md
├── INDEX.md
├── .env.example
├── docker-compose.yml
├── turbo.json
├── package.json
├── apps/
│   ├── web/              # Next.js frontend
│   ├── api/              # Node.js/Express or NestJS backend
│   ├── mobile/           # React Native or Expo
│   └── admin/            # Admin dashboard
├── packages/
│   ├── ui/               # Shared component library
│   ├── config/           # Shared configs (eslint, tsconfig)
│   ├── database/         # Prisma schema & migrations
│   └── utils/            # Shared utilities
├── scripts/
│   ├── setup.sh
│   ├── seed.ts
│   ├── deploy.sh
│   └── test-all.sh
├── prompts/
│   ├── unit1/
│   ├── unit2/
│   └── ...unit10/
└── docs/
    ├── UNIT1.md → UNIT10.md
    ├── SUMMARY.md
    ├── APPENDIX.md
    └── RESOURCES.md
```

---

## Initialize Monorepo

```bash
mkdir thanos-promptology && cd thanos-promptology

# Turborepo monorepo
npx create-turbo@latest . --package-manager pnpm

# Or manual init
git init
pnpm init
echo "node_modules\n.env\n.turbo\ndist\n.next\nbuild" > .gitignore
```

---

## Root package.json

```json
{
  "name": "thanos-promptology",
  "private": true,
  "scripts": {
    "dev": "turbo run dev",
    "build": "turbo run build",
    "test": "turbo run test",
    "lint": "turbo run lint",
    "db:push": "pnpm --filter database db:push",
    "db:studio": "pnpm --filter database db:studio",
    "deploy": "bash scripts/deploy.sh"
  },
  "devDependencies": {
    "turbo": "latest",
    "typescript": "^5.0.0",
    "prettier": "^3.0.0",
    "eslint": "^8.0.0"
  },
  "packageManager": "pnpm@9.0.0"
}
```

---

## .env.example

```env
# App
NODE_ENV=development
PORT=3001
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_API_URL=http://localhost:3001

# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/thanos_db
REDIS_URL=redis://localhost:6379

# Auth
JWT_SECRET=your_jwt_secret_here
NEXTAUTH_SECRET=your_nextauth_secret
NEXTAUTH_URL=http://localhost:3000

# Third-party
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
CLOUDINARY_URL=cloudinary://xxx:xxx@xxx
SENDGRID_API_KEY=SG.xxx
OPENAI_API_KEY=sk-xxx
```

---

## docker-compose.yml

```yaml
version: '3.9'
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: thanos_db
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  mailhog:
    image: mailhog/mailhog
    ports:
      - "1025:1025"
      - "8025:8025"

volumes:
  pgdata:
```

```bash
# Start all services
docker-compose up -d

# Stop all
docker-compose down

# Nuke volumes
docker-compose down -v
```
