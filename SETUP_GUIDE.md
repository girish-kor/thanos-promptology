# Thanos Promptology - Complete Project Setup

This is a fully scaffolded monorepo for full-stack development using Turborepo, Next.js, NestJS, and more.

## 📁 Project Structure

```
thanos-promptology/
├── .env.example              # Environment template
├── .eslintrc.json           # ESLint config
├── .gitignore               # Git ignore rules
├── .npmrc                   # npm/pnpm config
├── .prettierrc.json         # Code formatter config
├── .github/
│   └── workflows/
│       └── ci-cd.yml        # GitHub Actions CI/CD pipeline
├── Dockerfile               # Docker container config
├── docker-compose.yml       # Services (PostgreSQL, Redis, MailHog)
├── turbo.json              # Turborepo configuration
├── package.json            # Root package.json with scripts
├── tsconfig.json           # TypeScript base config
├── vite.config.ts          # Vite configuration
│
├── apps/                   # Applications
│   ├── web/               # Next.js frontend (port 3000)
│   │   ├── package.json
│   │   ├── next.config.js
│   │   └── README.md
│   ├── api/               # NestJS backend (port 3001)
│   │   ├── package.json
│   │   ├── src/           # API source code
│   │   └── README.md
│   ├── admin/             # Next.js admin dashboard (port 3002)
│   │   ├── package.json
│   │   ├── next.config.js
│   │   └── README.md
│   └── mobile/            # React Native/Expo app
│       ├── package.json
│       └── README.md
│
├── packages/               # Shared packages
│   ├── ui/                # Component library
│   │   ├── package.json
│   │   ├── src/
│   │   └── README.md
│   ├── config/            # Shared configs
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── README.md
│   ├── database/          # Prisma schema
│   │   ├── package.json
│   │   ├── prisma/
│   │   │   └── schema.prisma
│   │   └── README.md
│   └── utils/             # Utility functions
│       ├── package.json
│       ├── src/
│       └── README.md
│
├── scripts/               # Utility scripts
│   ├── setup.sh           # Initial setup script
│   ├── deploy.sh          # Deployment script
│   ├── seed.ts            # Database seeding
│   └── test-all.sh        # Run all tests
│
├── prompts/               # Prompt templates by unit
│   ├── unit1/
│   ├── unit2/
│   ├── ...
│   └── unit10/
│
└── docs/                  # Documentation
    ├── UNIT1.md - UNIT10.md
    ├── INDEX.md
    ├── SUMMARY.md
    ├── APPENDIX.md
    └── RESOURCES.md
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
pnpm install
```

### 2. Setup Environment

```bash
cp .env.example .env.local
# Edit .env.local with your configuration
```

### 3. Start Docker Services

```bash
docker-compose up -d
```

### 4. Setup Database

```bash
pnpm db:push
pnpm seed
```

### 5. Start Development

```bash
pnpm dev
```

## 📦 Installation Scripts

### Linux/Mac

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### Windows (PowerShell)

- Copy commands from `scripts/setup.sh` manually or use WSL

## 🛠️ Available Commands

### Development

- `pnpm dev` - Start all dev servers
- `pnpm build` - Build all packages
- `pnpm lint` - Lint all code
- `pnpm type-check` - TypeScript check
- `pnpm test` - Run all tests

### Database

- `pnpm db:push` - Sync schema with database
- `pnpm db:studio` - Open Prisma Studio
- `pnpm db:generate` - Generate Prisma client
- `pnpm seed` - Seed database

### Deployment

- `bash scripts/deploy.sh staging` - Deploy to staging
- `bash scripts/deploy.sh production` - Deploy to production

## 🐳 Docker Services

The `docker-compose.yml` includes:

- **PostgreSQL** (5432) - Main database
- **Redis** (6379) - Caching
- **MailHog** (8025) - Email testing

## 🔧 Configuration Files

| File                          | Purpose                        |
| ----------------------------- | ------------------------------ |
| `.env.example`                | Environment variables template |
| `.eslintrc.json`              | Code linting rules             |
| `.prettierrc.json`            | Code formatting rules          |
| `turbo.json`                  | Monorepo task orchestration    |
| `tsconfig.json`               | TypeScript configuration       |
| `docker-compose.yml`          | Service orchestration          |
| `.github/workflows/ci-cd.yml` | CI/CD pipeline                 |

## 📝 Next Steps

1. **Install dependencies**: `pnpm install`
2. **Configure environment**: Update `.env.local`
3. **Start services**: `docker-compose up -d`
4. **Setup database**: `pnpm db:push && pnpm seed`
5. **Start development**: `pnpm dev`

## 📚 Documentation

- [UNIT1-10](docs/) - Comprehensive guides and prompts
- [SUMMARY.md](docs/SUMMARY.md) - Quick reference
- [APPENDIX.md](docs/APPENDIX.md) - Additional resources
- [README](README.md) - Setup instructions

## 🚢 Deployment

### Frontend (Vercel)

```bash
vercel
```

### Backend (Railway)

```bash
railway login
railway up
```

### Docker

```bash
docker build -t thanos-api .
docker run -p 3001:3001 thanos-api
```

## 📞 Support

For detailed information, refer to the documentation files in the `/docs` folder.
