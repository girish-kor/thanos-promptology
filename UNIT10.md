# UNIT 10 — FULL END-TO-END PROJECT BLUEPRINTS USING THANOS PROMPTS

---

## 10.1 SaaS Starter Blueprint

### Thanos Prompt

```
Build a complete SaaS starter application.

T: Multi-tenant SaaS with team workspaces, subscriptions, and role-based access
H: Next.js 14 + tRPC + Prisma + PostgreSQL + Stripe + NextAuth
A: Monorepo with Turborepo. Start from scratch.
N: Generate complete implementation:
O: Multi-tenancy via organizationId, not separate DBs
S: Repository pattern, strict TypeScript

Features:
1. Auth: email/password + Google OAuth
2. Organizations: create, invite members, manage roles
3. Billing: Stripe subscriptions (Free, Pro, Enterprise)
4. Dashboard: usage metrics per organization
5. Settings: profile, org settings, billing portal
6. API keys: generate, list, revoke

Generate all files with paths.
```

### SaaS Database Schema

```prisma
// prisma/schema.prisma (SaaS)
model Organization {
  id          String   @id @default(cuid())
  name        String
  slug        String   @unique
  plan        Plan     @default(FREE)
  stripeCustomerId    String?  @unique
  stripeSubscriptionId String? @unique
  currentPeriodEnd    DateTime?
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  members     OrganizationMember[]
  apiKeys     ApiKey[]
  invitations Invitation[]

  @@map("organizations")
}

model OrganizationMember {
  id             String           @id @default(cuid())
  organizationId String
  userId         String
  role           OrgRole          @default(MEMBER)
  joinedAt       DateTime         @default(now())

  organization   Organization     @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  user           User             @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([organizationId, userId])
  @@map("organization_members")
}

model Invitation {
  id             String       @id @default(cuid())
  email          String
  organizationId String
  role           OrgRole      @default(MEMBER)
  token          String       @unique @default(cuid())
  expiresAt      DateTime
  acceptedAt     DateTime?
  createdAt      DateTime     @default(now())

  organization   Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)

  @@map("invitations")
}

model ApiKey {
  id             String       @id @default(cuid())
  name           String
  keyHash        String       @unique
  keyPrefix      String
  organizationId String
  createdById    String
  lastUsedAt     DateTime?
  expiresAt      DateTime?
  createdAt      DateTime     @default(now())
  revokedAt      DateTime?

  organization   Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)

  @@index([organizationId])
  @@map("api_keys")
}

enum Plan { FREE PRO ENTERPRISE }
enum OrgRole { OWNER ADMIN MEMBER VIEWER }
```

### SaaS Folder Structure

```
apps/web/
├── app/
│   ├── (auth)/login, register
│   ├── (app)/
│   │   ├── layout.tsx           # Org context provider
│   │   ├── dashboard/page.tsx
│   │   ├── settings/
│   │   │   ├── profile/
│   │   │   ├── organization/
│   │   │   ├── members/
│   │   │   ├── billing/
│   │   │   └── api-keys/
│   ├── api/
│   │   ├── auth/[...nextauth]/
│   │   ├── trpc/[trpc]/
│   │   └── webhooks/stripe/
├── components/
│   ├── layout/AppShell.tsx
│   ├── org/OrgSwitcher.tsx
│   └── billing/PricingTable.tsx
└── server/api/routers/
    ├── org.ts
    ├── members.ts
    ├── billing.ts
    └── apiKeys.ts
```

---

## 10.2 E-Commerce Platform Blueprint

### Thanos Prompt

```
Build a production-ready e-commerce platform.

T: Full e-commerce with products, cart, checkout, orders, admin
H: Next.js 14 App Router + Prisma + PostgreSQL + Stripe + Cloudinary
N: Generate complete implementation

Features:
1. Product catalog: categories, variants (size/color), images
2. Search: full-text + filters (price, category, rating)
3. Cart: persistent (DB for logged-in, localStorage for guest)
4. Checkout: Stripe payment + address + order confirmation email
5. Orders: tracking, status updates
6. Admin: product CRUD, order management, analytics dashboard
7. Reviews: create, moderate, aggregate ratings

Generate all files.
```

### E-Commerce Schema

```prisma
model Product {
  id          String   @id @default(cuid())
  name        String
  slug        String   @unique
  description String   @db.Text
  price       Decimal  @db.Decimal(10, 2)
  comparePrice Decimal? @db.Decimal(10, 2)
  sku         String   @unique
  stock       Int      @default(0)
  published   Boolean  @default(false)
  featured    Boolean  @default(false)
  categoryId  String
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  deletedAt   DateTime?

  category    Category    @relation(fields: [categoryId], references: [id])
  images      ProductImage[]
  variants    ProductVariant[]
  reviews     Review[]
  cartItems   CartItem[]
  orderItems  OrderItem[]

  @@index([slug])
  @@index([categoryId])
  @@index([published, featured])
  @@map("products")
}

model Order {
  id                    String      @id @default(cuid())
  orderNumber           String      @unique
  userId                String?
  status                OrderStatus @default(PENDING)
  stripePaymentIntentId String?
  subtotal              Decimal     @db.Decimal(10, 2)
  tax                   Decimal     @db.Decimal(10, 2)
  shipping              Decimal     @db.Decimal(10, 2)
  total                 Decimal     @db.Decimal(10, 2)
  shippingAddress       Json
  createdAt             DateTime    @default(now())
  paidAt                DateTime?

  items   OrderItem[]
  user    User?       @relation(fields: [userId], references: [id])

  @@map("orders")
}

enum OrderStatus {
  PENDING PAID PROCESSING SHIPPED DELIVERED CANCELLED REFUNDED
}
```

---

## 10.3 AI-Powered App Blueprint

### Thanos Prompt

```
Build an AI-powered full stack application.

T: AI writing assistant with streaming responses, conversation history, document upload
H: Next.js 14 + OpenAI SDK + Vercel AI SDK + Prisma + PostgreSQL + Cloudinary
N: Generate complete implementation

Features:
1. Chat interface with streaming AI responses
2. Multiple AI personas/system prompts
3. Conversation history (save, load, delete)
4. Document upload: PDF/text → RAG (basic)
5. Token usage tracking per user
6. Rate limiting by plan (free: 50 msgs/day, pro: unlimited)
7. Prompt templates library

Generate all files.
```

### AI Chat Implementation

```typescript
// app/api/chat/route.ts
import { openai } from "@ai-sdk/openai";
import { streamText } from "ai";
import { auth } from "@/lib/auth";
import { prisma } from "@/lib/db";
import { checkRateLimit } from "@/lib/rateLimit";

export const runtime = "edge";
export const maxDuration = 30;

export async function POST(req: Request) {
  const session = await auth();
  if (!session?.user) return new Response("Unauthorized", { status: 401 });

  const { messages, conversationId, systemPrompt } = await req.json();

  // Rate limit check
  const allowed = await checkRateLimit(session.user.id);
  if (!allowed) return new Response("Rate limit exceeded", { status: 429 });

  const result = streamText({
    model: openai("gpt-4o-mini"),
    system: systemPrompt || "You are a helpful assistant.",
    messages,
    onFinish: async ({ text, usage }) => {
      // Save conversation
      await prisma.message.createMany({
        data: [
          ...messages.slice(-1).map((m: any) => ({
            conversationId,
            role: m.role,
            content: m.content,
            userId: session.user.id,
          })),
          {
            conversationId,
            role: "assistant",
            content: text,
            userId: session.user.id,
            tokensUsed: usage.completionTokens,
          },
        ],
      });

      // Track usage
      await prisma.tokenUsage.create({
        data: {
          userId: session.user.id,
          promptTokens: usage.promptTokens,
          completionTokens: usage.completionTokens,
          totalTokens: usage.totalTokens,
        },
      });
    },
  });

  return result.toDataStreamResponse();
}
```

```typescript
// components/ChatInterface.tsx
"use client";

import { useChat } from "ai/react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Send } from "lucide-react";

interface ChatInterfaceProps {
  conversationId: string;
  initialMessages?: { role: string; content: string }[];
}

export function ChatInterface({ conversationId, initialMessages = [] }: ChatInterfaceProps) {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat({
    api: "/api/chat",
    body: { conversationId },
    initialMessages: initialMessages as any,
  });

  return (
    <div className="flex flex-col h-full">
      <ScrollArea className="flex-1 p-4">
        <div className="space-y-4">
          {messages.map((message) => (
            <div
              key={message.id}
              className={`flex ${message.role === "user" ? "justify-end" : "justify-start"}`}
            >
              <div
                className={`max-w-[80%] rounded-lg p-3 text-sm ${
                  message.role === "user"
                    ? "bg-primary text-primary-foreground"
                    : "bg-muted"
                }`}
              >
                {message.content}
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-muted rounded-lg p-3 text-sm">
                <span className="animate-pulse">●●●</span>
              </div>
            </div>
          )}
        </div>
      </ScrollArea>

      <form onSubmit={handleSubmit} className="p-4 border-t flex gap-2">
        <Input
          value={input}
          onChange={handleInputChange}
          placeholder="Type a message..."
          disabled={isLoading}
          className="flex-1"
        />
        <Button type="submit" size="icon" disabled={isLoading || !input.trim()}>
          <Send className="h-4 w-4" />
        </Button>
      </form>
    </div>
  );
}
```

---

## 10.4 End-to-End Launch Checklist Script

```bash
#!/bin/bash
# scripts/pre-launch-check.sh

set -e
echo "🚀 PRE-LAUNCH CHECKLIST"

# 1. Environment variables
echo "Checking env vars..."
REQUIRED_VARS=(DATABASE_URL REDIS_URL JWT_SECRET NEXTAUTH_SECRET STRIPE_SECRET_KEY)
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ Missing: $var"
    exit 1
  fi
done
echo "✅ All env vars present"

# 2. Database
echo "Checking database..."
npx prisma migrate status
echo "✅ Database migrations up to date"

# 3. Tests
echo "Running tests..."
pnpm test --coverage --reporter=verbose
echo "✅ All tests passing"

# 4. Build
echo "Building..."
pnpm build
echo "✅ Build successful"

# 5. Security audit
echo "Security audit..."
npm audit --audit-level=high
echo "✅ No high/critical vulnerabilities"

# 6. Type check
echo "Type checking..."
pnpm typecheck
echo "✅ No type errors"

echo ""
echo "🎉 ALL CHECKS PASSED — Ready to deploy!"
```

---

## 10.5 Monorepo Quick Start (Any Blueprint)

```bash
#!/bin/bash
# One command to start any blueprint

BLUEPRINT=$1  # saas | ecommerce | ai | social | realtime

curl -fsSL https://raw.githubusercontent.com/yourrepo/thanos-blueprints/main/$BLUEPRINT/setup.sh | bash

# Then:
cd $BLUEPRINT
cp .env.example .env  # Fill in your values
docker-compose up -d  # Start postgres + redis
pnpm install
pnpm db:push
pnpm db:seed
pnpm dev

echo "🔥 $BLUEPRINT running at http://localhost:3000"
echo "📊 API at http://localhost:3001"
echo "📬 Mail UI at http://localhost:8025"
echo "🗄️  DB Studio: pnpm db:studio"
```
