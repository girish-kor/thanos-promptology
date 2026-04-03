# UNIT 9 — PERFORMANCE OPTIMIZATION SCRIPTS

---

## 9.1 Thanos Prompt — Performance Audit

```
You are a performance engineer. Audit and optimize this codebase.

Stack: Next.js 14 + Node.js + PostgreSQL + Redis
Target metrics:
  - Lighthouse: >90 Performance, >90 Accessibility
  - Core Web Vitals: LCP < 2.5s, FID < 100ms, CLS < 0.1
  - API p95 response time < 200ms
  - DB query time < 50ms for common queries

Audit:
[PASTE CODE OR DESCRIBE ARCHITECTURE]

Generate:
1. Next.js optimization config (next.config.ts)
2. Database query optimizations (add indexes, fix N+1)
3. Redis caching strategy for top 5 endpoints
4. Image optimization setup
5. Bundle analysis and code splitting plan
6. React optimization (memo, useMemo, useCallback placements)

Output: Executable changes only. Show before/after for each.
```

---

## 9.2 Next.js Performance Config

```typescript
// next.config.ts
import type { NextConfig } from "next";
import bundleAnalyzer from "@next/bundle-analyzer";

const withBundleAnalyzer = bundleAnalyzer({
  enabled: process.env.ANALYZE === "true",
});

const config: NextConfig = {
  // Compiler optimizations
  compiler: {
    removeConsole: process.env.NODE_ENV === "production",
  },

  // Image optimization
  images: {
    formats: ["image/avif", "image/webp"],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920],
    minimumCacheTTL: 86400,
    remotePatterns: [
      { protocol: "https", hostname: "res.cloudinary.com" },
      { protocol: "https", hostname: "avatars.githubusercontent.com" },
    ],
  },

  // Headers for caching
  async headers() {
    return [
      {
        source: "/:path*",
        headers: [
          { key: "X-DNS-Prefetch-Control", value: "on" },
          { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
        ],
      },
      {
        source: "/api/:path*",
        headers: [{ key: "Cache-Control", value: "no-store" }],
      },
      {
        source: "/_next/static/:path*",
        headers: [{ key: "Cache-Control", value: "public, max-age=31536000, immutable" }],
      },
    ];
  },

  // Webpack optimizations
  webpack: (config, { dev, isServer }) => {
    if (!dev && !isServer) {
      config.optimization = {
        ...config.optimization,
        splitChunks: {
          chunks: "all",
          cacheGroups: {
            vendor: {
              test: /[\\/]node_modules[\\/]/,
              name: "vendors",
              chunks: "all",
            },
          },
        },
      };
    }
    return config;
  },

  experimental: {
    optimizePackageImports: ["lucide-react", "@radix-ui/react-icons"],
  },
};

export default withBundleAnalyzer(config);
```

```bash
# Run bundle analysis
ANALYZE=true pnpm build

# Install bundle analyzer
pnpm add -D @next/bundle-analyzer
```

---

## 9.3 Database Query Optimization

```sql
-- Add indexes for common query patterns
-- Run after prisma migrate

-- Users: lookup by email
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_role ON users(role) WHERE deleted_at IS NULL;

-- Posts: common query patterns
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_author_id ON posts(author_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_published_created ON posts(published, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_search ON posts USING gin(to_tsvector('english', title || ' ' || coalesce(content, '')));

-- Full-text search function
CREATE OR REPLACE FUNCTION search_posts(query TEXT)
RETURNS TABLE(id TEXT, title TEXT, rank REAL) AS $$
  SELECT id, title, ts_rank(
    to_tsvector('english', title || ' ' || coalesce(content, '')),
    plainto_tsquery('english', query)
  ) AS rank
  FROM posts
  WHERE deleted_at IS NULL
    AND to_tsvector('english', title || ' ' || coalesce(content, '')) @@ plainto_tsquery('english', query)
  ORDER BY rank DESC;
$$ LANGUAGE sql STABLE;
```

```typescript
// Fix N+1: use Prisma includes instead of nested loops

// ❌ BAD: N+1 query
const posts = await prisma.post.findMany();
for (const post of posts) {
  post.author = await prisma.user.findUnique({ where: { id: post.authorId } });
}

// ✅ GOOD: Single query with include
const posts = await prisma.post.findMany({
  include: {
    author: { select: { id: true, name: true, image: true } },
  },
});

// ✅ BETTER: Select only needed fields
const posts = await prisma.post.findMany({
  select: {
    id: true,
    title: true,
    createdAt: true,
    author: { select: { name: true } },
  },
});
```

---

## 9.4 Redis Caching Middleware (Express)

```typescript
// src/middleware/cache.ts
import { cache } from "../lib/cache";
import type { Request, Response, NextFunction } from "express";

interface CacheOptions {
  ttl?: number;
  keyFn?: (req: Request) => string;
  condition?: (req: Request) => boolean;
}

export function cacheMiddleware({
  ttl = 300,
  keyFn = (req) => `cache:${req.method}:${req.originalUrl}`,
  condition = () => true,
}: CacheOptions = {}) {
  return async (req: Request, res: Response, next: NextFunction) => {
    if (req.method !== "GET" || !condition(req)) return next();

    const key = keyFn(req);
    const cached = await cache.get(key);

    if (cached) {
      res.setHeader("X-Cache", "HIT");
      return res.json(cached);
    }

    // Intercept response to cache it
    const originalJson = res.json.bind(res);
    res.json = (data) => {
      if (res.statusCode === 200) {
        cache.set(key, data, ttl).catch(console.error);
      }
      res.setHeader("X-Cache", "MISS");
      return originalJson(data);
    };

    next();
  };
}

// Cache invalidation helper
export async function invalidateCache(pattern: string) {
  await cache.delPattern(`cache:*${pattern}*`);
}

// Usage:
// router.get("/posts", cacheMiddleware({ ttl: 60 }), getPosts);
// After create/update/delete: await invalidateCache("/posts");
```

---

## 9.5 React Performance Optimizations

```typescript
// ❌ BAD: Re-renders on every parent update
function ExpensiveList({ items, onDelete }) {
  return items.map(item => (
    <ExpensiveItem key={item.id} item={item} onDelete={onDelete} />
  ));
}

// ✅ GOOD: Memoized component + stable callback
import { memo, useCallback, useMemo } from "react";

const ExpensiveItem = memo(function ExpensiveItem({ item, onDelete }) {
  return <div onClick={() => onDelete(item.id)}>{item.name}</div>;
});

function ExpensiveList({ items, userId, onDelete }) {
  // Stable callback reference
  const handleDelete = useCallback((id: string) => {
    onDelete(id);
  }, [onDelete]);

  // Expensive computation memoized
  const sortedItems = useMemo(
    () => [...items].sort((a, b) => b.createdAt - a.createdAt),
    [items]
  );

  return sortedItems.map(item => (
    <ExpensiveItem key={item.id} item={item} onDelete={handleDelete} />
  ));
}
```

```typescript
// Virtualized list for large datasets
import { useVirtualizer } from "@tanstack/react-virtual";
import { useRef } from "react";

function VirtualList({ items }: { items: { id: string; name: string }[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const rowVirtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 60,
    overscan: 5,
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div style={{ height: rowVirtualizer.getTotalSize(), position: "relative" }}>
        {rowVirtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={items[virtualItem.index]!.id}
            style={{
              position: "absolute",
              top: 0,
              left: 0,
              width: "100%",
              height: `${virtualItem.size}px`,
              transform: `translateY(${virtualItem.start}px)`,
            }}
          >
            {items[virtualItem.index]!.name}
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

## 9.6 BullMQ Background Jobs

```bash
npm install bullmq ioredis
```

```typescript
// src/jobs/queue.ts
import { Queue, Worker, QueueEvents } from "bullmq";
import { Redis } from "ioredis";

const connection = new Redis(process.env.REDIS_URL!, { maxRetriesPerRequest: null });

// Define queues
export const emailQueue = new Queue("email", { connection });
export const imageQueue = new Queue("image-processing", { connection });
export const reportQueue = new Queue("reports", { connection });

// Email worker
new Worker("email", async (job) => {
  const { to, subject, html } = job.data;
  await sendEmail({ to, subject, html });
  return { sent: true };
}, {
  connection,
  concurrency: 10,
  limiter: { max: 100, duration: 60_000 }, // 100 emails/min
});

// Image processing worker
new Worker("image-processing", async (job) => {
  const { imageUrl, userId } = job.data;
  // Resize, compress, upload to CDN
  const optimizedUrl = await processImage(imageUrl);
  await prisma.user.update({ where: { id: userId }, data: { image: optimizedUrl } });
}, { connection, concurrency: 3 });

// Add jobs
export async function queueEmail(data: { to: string; subject: string; html: string }) {
  await emailQueue.add("send", data, {
    attempts: 3,
    backoff: { type: "exponential", delay: 2000 },
    removeOnComplete: 100,
    removeOnFail: 50,
  });
}

// Queue dashboard (Bull Board)
import { createBullBoard } from "@bull-board/api";
import { BullMQAdapter } from "@bull-board/api/bullMQAdapter";
import { ExpressAdapter } from "@bull-board/express";

const serverAdapter = new ExpressAdapter();
serverAdapter.setBasePath("/admin/queues");

createBullBoard({
  queues: [new BullMQAdapter(emailQueue), new BullMQAdapter(imageQueue)],
  serverAdapter,
});

// app.use("/admin/queues", authenticate, authorize("ADMIN"), serverAdapter.getRouter());
```

---

## 9.7 API Rate Limiting

```typescript
// src/middleware/rateLimit.ts
import rateLimit from "express-rate-limit";
import RedisStore from "rate-limit-redis";
import { Redis } from "ioredis";

const redis = new Redis(process.env.REDIS_URL!);

export const globalRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  store: new RedisStore({
    sendCommand: (...args: string[]) => redis.call(...args),
  }),
  message: { success: false, message: "Too many requests, please try again later" },
});

export const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10, // 10 login attempts per 15 min
  skipSuccessfulRequests: true,
  message: { success: false, message: "Too many login attempts" },
});

export const apiRateLimit = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 60,
  keyGenerator: (req) => req.user?.id ?? req.ip ?? "unknown",
});

// app.use(globalRateLimit);
// app.use("/api/auth", authRateLimit);
// app.use("/api", authenticate, apiRateLimit);
```

---

## 9.8 Performance Monitoring

```typescript
// src/middleware/metrics.ts
import { Registry, Counter, Histogram, Gauge } from "prom-client";

const register = new Registry();

export const httpRequestsTotal = new Counter({
  name: "http_requests_total",
  help: "Total HTTP requests",
  labelNames: ["method", "route", "status"],
  registers: [register],
});

export const httpRequestDuration = new Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request duration",
  labelNames: ["method", "route"],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5],
  registers: [register],
});

export const activeConnections = new Gauge({
  name: "active_connections",
  help: "Active connections",
  registers: [register],
});

export function metricsMiddleware(req: any, res: any, next: any) {
  const start = Date.now();
  activeConnections.inc();

  res.on("finish", () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route?.path ?? req.path;
    httpRequestsTotal.labels(req.method, route, res.statusCode).inc();
    httpRequestDuration.labels(req.method, route).observe(duration);
    activeConnections.dec();
  });

  next();
}

// Expose metrics endpoint
// app.get("/metrics", async (req, res) => {
//   res.set("Content-Type", register.contentType);
//   res.end(await register.metrics());
// });
```
