# @thanos/database

Prisma schema and database utilities for Thanos Promptology.

## Setup

```bash
pnpm install
pnpm generate
```

## Prisma Schema

The database schema is defined in `prisma/schema.prisma`.

## Scripts

- `pnpm generate` - Generate Prisma client
- `pnpm db:push` - Push schema to database
- `pnpm db:studio` - Open Prisma Studio
- `pnpm migrate` - Deploy migrations
- `pnpm seed` - Seed database with sample data
- `pnpm reset` - Reset database (WARNING: destructive)

## Database

Default: PostgreSQL on `localhost:5432`

See `.env.example` for environment variables.

## Creating Migrations

1. Update `prisma/schema.prisma`
2. Run: `npx prisma migrate dev --name migration_name`
3. Prisma will generate SQL migration files

## Models

- User
- Project
- Task
- Comment

Add more models to `schema.prisma` as needed.

## Seed

Populate sample data in `prisma/seed.ts`:

```bash
pnpm seed
```

## Prisma Studio

Visual database explorer:

```bash
pnpm db:studio
```
