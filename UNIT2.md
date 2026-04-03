# UNIT 2 — FULL STACK PROJECT SCAFFOLD SCRIPTS

---

## 2.1 Next.js + Prisma + PostgreSQL (Production Stack)

```bash
#!/bin/bash
# scaffold-nextjs-prisma.sh

APP_NAME=$1
if [ -z "$APP_NAME" ]; then echo "Usage: ./scaffold-nextjs-prisma.sh myapp"; exit 1; fi

# Create Next.js app
npx create-next-app@latest $APP_NAME \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --no-turbopack

cd $APP_NAME

# Core dependencies
pnpm add \
  prisma @prisma/client \
  next-auth @auth/prisma-adapter \
  zod \
  @tanstack/react-query \
  axios \
  zustand \
  react-hook-form @hookform/resolvers \
  date-fns \
  clsx tailwind-merge \
  lucide-react

# shadcn/ui
pnpm dlx shadcn@latest init -d
pnpm dlx shadcn@latest add button input label card dialog table badge

# Dev dependencies
pnpm add -D \
  @types/node \
  vitest @testing-library/react @testing-library/jest-dom \
  playwright \
  prettier prettier-plugin-tailwindcss \
  @trivago/prettier-plugin-sort-imports

# Prisma init
pnpm dlx prisma init --datasource-provider postgresql

# Create folder structure
mkdir -p src/{actions,components/{ui,forms,layout},hooks,lib/{api,auth,db},types,utils,validators}
mkdir -p prisma/migrations

echo "✅ $APP_NAME scaffolded successfully"
```

### Prisma Schema (Full Base Schema)

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  emailVerified DateTime?
  name          String?
  image         String?
  password      String?
  role          Role      @default(USER)
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  deletedAt     DateTime?

  accounts Account[]
  sessions Session[]
  posts    Post[]

  @@index([email])
  @@map("users")
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String? @db.Text
  access_token      String? @db.Text
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String? @db.Text
  session_state     String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
  @@map("accounts")
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("sessions")
}

model Post {
  id        String    @id @default(cuid())
  title     String
  content   String?   @db.Text
  published Boolean   @default(false)
  authorId  String
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
  deletedAt DateTime?

  author User @relation(fields: [authorId], references: [id])

  @@index([authorId])
  @@index([published])
  @@map("posts")
}

enum Role {
  USER
  ADMIN
  MODERATOR
}
```

### lib/db.ts

```typescript
// src/lib/db.ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["query", "error"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
```

---

## 2.2 NestJS + PostgreSQL + TypeORM Scaffold

```bash
#!/bin/bash
# scaffold-nestjs.sh

APP_NAME=$1
npm i -g @nestjs/cli

nest new $APP_NAME --package-manager pnpm --strict
cd $APP_NAME

pnpm add \
  @nestjs/config \
  @nestjs/typeorm typeorm pg \
  @nestjs/jwt passport-jwt @nestjs/passport passport \
  @nestjs/swagger swagger-ui-express \
  class-validator class-transformer \
  bcryptjs \
  redis ioredis

pnpm add -D \
  @types/passport-jwt \
  @types/bcryptjs \
  @faker-js/faker

# Generate core modules
nest g module auth
nest g module users
nest g module posts

nest g controller auth --no-spec
nest g controller users
nest g controller posts

nest g service auth
nest g service users
nest g service posts

echo "✅ NestJS app $APP_NAME ready"
```

### NestJS Folder Structure

```
src/
├── main.ts
├── app.module.ts
├── common/
│   ├── decorators/
│   │   ├── current-user.decorator.ts
│   │   └── roles.decorator.ts
│   ├── filters/
│   │   └── http-exception.filter.ts
│   ├── guards/
│   │   ├── jwt-auth.guard.ts
│   │   └── roles.guard.ts
│   ├── interceptors/
│   │   └── transform.interceptor.ts
│   └── pipes/
│       └── validation.pipe.ts
├── config/
│   ├── database.config.ts
│   └── jwt.config.ts
├── auth/
│   ├── auth.module.ts
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── strategies/
│   │   └── jwt.strategy.ts
│   └── dto/
│       ├── login.dto.ts
│       └── register.dto.ts
└── users/
    ├── users.module.ts
    ├── users.controller.ts
    ├── users.service.ts
    ├── entities/
    │   └── user.entity.ts
    └── dto/
        ├── create-user.dto.ts
        └── update-user.dto.ts
```

---

## 2.3 T3 Stack (tRPC + Prisma + Next.js)

```bash
#!/bin/bash
# scaffold-t3.sh

APP_NAME=$1
pnpm create t3-app@latest $APP_NAME \
  --CI \
  --trpc \
  --prisma \
  --nextAuth \
  --tailwind \
  --appRouter \
  --dbProvider postgresql \
  --noGit

cd $APP_NAME

# Additional packages
pnpm add \
  @tanstack/react-query \
  zod \
  zustand \
  @uploadthing/react uploadthing \
  react-hot-toast

pnpm dlx shadcn@latest init -d
pnpm dlx shadcn@latest add button input card table dialog

echo "✅ T3 Stack ready: $APP_NAME"
```

### tRPC Router Example

```typescript
// src/server/api/routers/post.ts
import { z } from "zod";
import {
  createTRPCRouter,
  protectedProcedure,
  publicProcedure,
} from "@/server/api/trpc";

export const postRouter = createTRPCRouter({
  getAll: publicProcedure
    .input(
      z.object({
        page: z.number().min(1).default(1),
        limit: z.number().min(1).max(100).default(10),
      })
    )
    .query(async ({ ctx, input }) => {
      const { page, limit } = input;
      const skip = (page - 1) * limit;

      const [posts, total] = await Promise.all([
        ctx.db.post.findMany({
          skip,
          take: limit,
          where: { deletedAt: null, published: true },
          include: { author: { select: { name: true, image: true } } },
          orderBy: { createdAt: "desc" },
        }),
        ctx.db.post.count({ where: { deletedAt: null, published: true } }),
      ]);

      return { posts, total, totalPages: Math.ceil(total / limit), page };
    }),

  create: protectedProcedure
    .input(
      z.object({
        title: z.string().min(1).max(200),
        content: z.string().optional(),
        published: z.boolean().default(false),
      })
    )
    .mutation(async ({ ctx, input }) => {
      return ctx.db.post.create({
        data: { ...input, authorId: ctx.session.user.id },
      });
    }),

  delete: protectedProcedure
    .input(z.object({ id: z.string() }))
    .mutation(async ({ ctx, input }) => {
      return ctx.db.post.update({
        where: { id: input.id, authorId: ctx.session.user.id },
        data: { deletedAt: new Date() },
      });
    }),
});
```

---

## 2.4 MERN Stack Scaffold

```bash
#!/bin/bash
# scaffold-mern.sh

APP_NAME=$1
mkdir $APP_NAME && cd $APP_NAME

# Backend
mkdir server && cd server
npm init -y
npm install express mongoose dotenv cors helmet morgan bcryptjs jsonwebtoken zod express-async-errors
npm install -D typescript ts-node nodemon @types/express @types/node @types/cors @types/bcryptjs @types/jsonwebtoken
npx tsc --init --rootDir src --outDir dist --strict

mkdir -p src/{routes,controllers,models,middleware,services,utils,validators,types}

cat > src/index.ts << 'EOF'
import 'express-async-errors';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { errorHandler } from './middleware/errorHandler';
import authRoutes from './routes/auth';
import userRoutes from './routes/users';

const app = express();
const PORT = process.env.PORT || 3001;

app.use(helmet());
app.use(cors({ origin: process.env.FRONTEND_URL, credentials: true }));
app.use(morgan('dev'));
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use(errorHandler);

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
export default app;
EOF

cd ..

# Frontend
npx create-react-app client --template typescript
cd client
npm install axios @tanstack/react-query react-router-dom zustand react-hook-form zod @hookform/resolvers

echo "✅ MERN stack ready"
```

---

## 2.5 Express + Drizzle ORM Scaffold

```bash
#!/bin/bash
APP_NAME=$1
mkdir $APP_NAME && cd $APP_NAME

pnpm init
pnpm add express drizzle-orm @neondatabase/serverless
pnpm add -D typescript drizzle-kit @types/express tsx nodemon

mkdir -p src/{db/{schema,migrations},routes,controllers,services,middleware,utils}

cat > src/db/schema/users.ts << 'EOF'
import { pgTable, text, timestamp, boolean, pgEnum } from "drizzle-orm/pg-core";
import { createId } from "@paralleldrive/cuid2";

export const roleEnum = pgEnum("role", ["USER", "ADMIN"]);

export const users = pgTable("users", {
  id: text("id").primaryKey().$defaultFn(() => createId()),
  email: text("email").notNull().unique(),
  name: text("name"),
  password: text("password"),
  role: roleEnum("role").default("USER").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
  deletedAt: timestamp("deleted_at"),
});
EOF

cat > drizzle.config.ts << 'EOF'
import type { Config } from "drizzle-kit";
export default {
  schema: "./src/db/schema/*",
  out: "./src/db/migrations",
  driver: "pg",
  dbCredentials: { connectionString: process.env.DATABASE_URL! },
} satisfies Config;
EOF

echo '{ "scripts": { "db:generate": "drizzle-kit generate", "db:push": "drizzle-kit push", "db:studio": "drizzle-kit studio", "dev": "tsx watch src/index.ts" } }' | pnpm pkg set scripts --json

echo "✅ Drizzle ORM scaffold ready"
```

---

## 2.6 Seed Script

```typescript
// scripts/seed.ts
import { PrismaClient } from "@prisma/client";
import { hash } from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Seeding database...");

  // Clean
  await prisma.post.deleteMany();
  await prisma.user.deleteMany();

  // Admin user
  const admin = await prisma.user.create({
    data: {
      email: "admin@example.com",
      name: "Admin User",
      password: await hash("Admin123!", 12),
      role: "ADMIN",
      emailVerified: new Date(),
    },
  });

  // Regular users
  const users = await Promise.all(
    Array.from({ length: 5 }, (_, i) =>
      prisma.user.create({
        data: {
          email: `user${i + 1}@example.com`,
          name: `User ${i + 1}`,
          password: await hash("User123!", 12),
          emailVerified: new Date(),
        },
      })
    )
  );

  // Posts
  const allUsers = [admin, ...users];
  await Promise.all(
    Array.from({ length: 20 }, (_, i) =>
      prisma.post.create({
        data: {
          title: `Post ${i + 1}: Getting Started with Full Stack Development`,
          content: `Content for post ${i + 1}. This is sample seeded data.`,
          published: Math.random() > 0.3,
          authorId: allUsers[Math.floor(Math.random() * allUsers.length)]!.id,
        },
      })
    )
  );

  console.log("✅ Seeding complete");
  console.log(`   Admin: admin@example.com / Admin123!`);
  console.log(`   Users: user1-5@example.com / User123!`);
}

main().catch(console.error).finally(() => prisma.$disconnect());
```

```bash
# Run seed
npx tsx scripts/seed.ts
# or
npx prisma db seed
```
