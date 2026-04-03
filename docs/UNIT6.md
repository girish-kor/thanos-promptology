# UNIT 6 — TESTING, DEBUGGING & QA AUTOMATION PROMPTS

---

## 6.1 Test Generator Prompt

```
You are a senior QA engineer.

Generate a complete test suite for this code:
```[language]
[PASTE CODE]
```

Stack: [Vitest / Jest] + [Testing Library (for React) / Supertest (for API)]

Generate tests for:
1. Happy path (all valid inputs)
2. Edge cases (empty, null, max values, special chars)
3. Error cases (invalid input, network failure, DB error)
4. Integration (if API: test full request/response cycle)

Requirements:
- Use descriptive test names: "should [action] when [condition]"
- Mock all external dependencies (DB, APIs, email)
- Setup/teardown with beforeEach/afterEach
- Test coverage target: >90% for this function/module
- No skipped tests

Output: Complete test file at [filename].test.ts
```

---

## 6.2 Vitest + Testing Library Setup

```bash
# Install
pnpm add -D vitest @vitejs/plugin-react \
  @testing-library/react @testing-library/jest-dom @testing-library/user-event \
  jsdom msw happy-dom

# vitest.config.ts
```

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/test/setup.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html", "lcov"],
      exclude: ["node_modules", "src/test"],
      thresholds: { branches: 80, functions: 80, lines: 80, statements: 80 },
    },
  },
  resolve: {
    alias: { "@": path.resolve(__dirname, "./src") },
  },
});
```

```typescript
// src/test/setup.ts
import "@testing-library/jest-dom";
import { afterAll, afterEach, beforeAll } from "vitest";
import { server } from "./mocks/server";

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

```typescript
// src/test/mocks/server.ts
import { setupServer } from "msw/node";
import { http, HttpResponse } from "msw";

export const handlers = [
  http.get("http://localhost:3001/api/posts", () =>
    HttpResponse.json({ posts: [], total: 0 })
  ),
  http.post("http://localhost:3001/api/auth/login", () =>
    HttpResponse.json({
      user: { id: "1", email: "test@test.com", name: "Test" },
      accessToken: "mock_token",
    })
  ),
];

export const server = setupServer(...handlers);
```

---

## 6.3 Service Unit Test Example

```typescript
// src/services/__tests__/post.service.test.ts
import { describe, it, expect, beforeEach, vi } from "vitest";
import { prisma } from "../../lib/db";
import * as postService from "../post.service";

vi.mock("../../lib/db", () => ({
  prisma: {
    post: {
      findMany: vi.fn(),
      findFirst: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      updateMany: vi.fn(),
      count: vi.fn(),
    },
  },
}));

const mockPost = {
  id: "post_1",
  title: "Test Post",
  content: "Content",
  published: true,
  authorId: "user_1",
  createdAt: new Date(),
  updatedAt: new Date(),
  deletedAt: null,
};

describe("Post Service", () => {
  beforeEach(() => vi.clearAllMocks());

  describe("findMany", () => {
    it("should return paginated posts", async () => {
      vi.mocked(prisma.post.findMany).mockResolvedValue([mockPost]);
      vi.mocked(prisma.post.count).mockResolvedValue(1);

      const result = await postService.findMany({
        page: 1, limit: 10, sortBy: "createdAt", order: "desc",
      });

      expect(result.posts).toHaveLength(1);
      expect(result.total).toBe(1);
      expect(prisma.post.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ skip: 0, take: 10 })
      );
    });

    it("should filter by search term", async () => {
      vi.mocked(prisma.post.findMany).mockResolvedValue([]);
      vi.mocked(prisma.post.count).mockResolvedValue(0);

      await postService.findMany({
        page: 1, limit: 10, search: "typescript", sortBy: "createdAt", order: "desc",
      });

      expect(prisma.post.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            OR: expect.arrayContaining([
              expect.objectContaining({ title: expect.objectContaining({ contains: "typescript" }) }),
            ]),
          }),
        })
      );
    });
  });

  describe("create", () => {
    it("should create a post", async () => {
      vi.mocked(prisma.post.create).mockResolvedValue(mockPost);

      const result = await postService.create({
        title: "Test Post",
        content: "Content",
        author: { connect: { id: "user_1" } },
      });

      expect(result).toEqual(mockPost);
    });
  });

  describe("softDelete", () => {
    it("should set deletedAt not remove record", async () => {
      vi.mocked(prisma.post.updateMany).mockResolvedValue({ count: 1 });

      await postService.softDelete("post_1", "user_1");

      expect(prisma.post.updateMany).toHaveBeenCalledWith({
        where: { id: "post_1", authorId: "user_1", deletedAt: null },
        data: expect.objectContaining({ deletedAt: expect.any(Date) }),
      });
    });
  });
});
```

---

## 6.4 API Integration Test (Supertest)

```typescript
// src/__tests__/posts.api.test.ts
import request from "supertest";
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import app from "../index";
import { prisma } from "../lib/db";
import { signTestToken } from "../test/helpers";

let authToken: string;
let testUserId: string;

beforeAll(async () => {
  // Seed test data
  const user = await prisma.user.create({
    data: {
      email: `test-${Date.now()}@test.com`,
      name: "Test User",
      password: "hashed_password",
    },
  });
  testUserId = user.id;
  authToken = signTestToken({ id: user.id, email: user.email, role: "USER" });
});

afterAll(async () => {
  await prisma.post.deleteMany({ where: { authorId: testUserId } });
  await prisma.user.delete({ where: { id: testUserId } });
  await prisma.$disconnect();
});

describe("POST /api/posts", () => {
  it("should create post when authenticated", async () => {
    const res = await request(app)
      .post("/api/posts")
      .set("Authorization", `Bearer ${authToken}`)
      .send({ title: "Test Post", content: "Test content", published: true });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.title).toBe("Test Post");
    expect(res.body.data.authorId).toBe(testUserId);
  });

  it("should return 401 without auth token", async () => {
    const res = await request(app)
      .post("/api/posts")
      .send({ title: "Test" });
    expect(res.status).toBe(401);
  });

  it("should return 400 with invalid data", async () => {
    const res = await request(app)
      .post("/api/posts")
      .set("Authorization", `Bearer ${authToken}`)
      .send({ title: "" }); // Empty title should fail validation
    expect(res.status).toBe(400);
    expect(res.body.errors).toBeDefined();
  });
});

describe("GET /api/posts", () => {
  it("should return paginated posts", async () => {
    const res = await request(app).get("/api/posts?page=1&limit=5");
    expect(res.status).toBe(200);
    expect(res.body.pagination).toMatchObject({
      page: 1,
      limit: 5,
    });
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});
```

---

## 6.5 Playwright E2E Tests

```bash
# Install
pnpm add -D @playwright/test
npx playwright install chromium firefox webkit
```

```typescript
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "html",
  use: {
    baseURL: "http://localhost:3000",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "Mobile Chrome", use: { ...devices["Pixel 5"] } },
  ],
  webServer: {
    command: "pnpm dev",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
  },
});
```

```typescript
// e2e/auth.spec.ts
import { test, expect } from "@playwright/test";

test.describe("Authentication", () => {
  test("user can login with valid credentials", async ({ page }) => {
    await page.goto("/login");
    await page.getByLabel("Email").fill("user1@example.com");
    await page.getByLabel("Password").fill("User123!");
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page).toHaveURL("/dashboard");
    await expect(page.getByText("Welcome back")).toBeVisible();
  });

  test("shows error on invalid credentials", async ({ page }) => {
    await page.goto("/login");
    await page.getByLabel("Email").fill("wrong@test.com");
    await page.getByLabel("Password").fill("wrongpassword");
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page.getByText("Invalid email or password")).toBeVisible();
    await expect(page).toHaveURL("/login");
  });

  test("redirects unauthenticated to login", async ({ page }) => {
    await page.goto("/dashboard");
    await expect(page).toHaveURL(/\/login/);
  });
});

// e2e/posts.spec.ts
test.describe("Posts", () => {
  test.use({ storageState: "e2e/.auth/user.json" }); // pre-authenticated

  test("can create a new post", async ({ page }) => {
    await page.goto("/posts/new");
    await page.getByLabel("Title").fill("My E2E Test Post");
    await page.getByLabel("Content").fill("This is the content");
    await page.getByRole("button", { name: "Publish" }).click();
    await expect(page.getByText("Post created")).toBeVisible();
  });
});
```

---

## 6.6 Load Testing with k6

```javascript
// scripts/load-test.js
import http from "k6/http";
import { check, sleep } from "k6";
import { Rate } from "k6/metrics";

const errorRate = new Rate("errors");
const BASE_URL = __ENV.API_URL || "http://localhost:3001";

export const options = {
  stages: [
    { duration: "30s", target: 10 },   // Ramp up
    { duration: "1m", target: 50 },    // Stay at 50 users
    { duration: "30s", target: 100 },  // Peak
    { duration: "30s", target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<500", "p(99)<1000"],
    errors: ["rate<0.1"],
  },
};

let authToken = "";

export function setup() {
  const res = http.post(`${BASE_URL}/api/auth/login`, JSON.stringify({
    email: "user1@example.com",
    password: "User123!",
  }), { headers: { "Content-Type": "application/json" } });

  return { token: res.json("accessToken") };
}

export default function (data) {
  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${data.token}`,
  };

  // GET posts
  const listRes = http.get(`${BASE_URL}/api/posts?page=1&limit=10`, { headers });
  check(listRes, {
    "GET posts: status 200": (r) => r.status === 200,
    "GET posts: has data": (r) => r.json("data") !== null,
  }) || errorRate.add(1);

  sleep(1);

  // CREATE post
  const createRes = http.post(`${BASE_URL}/api/posts`, JSON.stringify({
    title: `Load test post ${Date.now()}`,
    content: "Load testing content",
    published: false,
  }), { headers });

  check(createRes, {
    "POST post: status 201": (r) => r.status === 201,
  }) || errorRate.add(1);

  sleep(0.5);
}
```

```bash
# Install k6
brew install k6  # Mac
# Run load test
k6 run scripts/load-test.js
k6 run --env API_URL=https://api.production.com scripts/load-test.js
```

---

## 6.7 Error Boundary (React)

```typescript
// components/ErrorBoundary.tsx
"use client";

import React, { Component, type ReactNode } from "react";
import { Button } from "@/components/ui/button";

interface Props { children: ReactNode; fallback?: ReactNode; }
interface State { hasError: boolean; error: Error | null; }

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error("ErrorBoundary caught:", error, info);
    // Send to error tracking: Sentry.captureException(error);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback ?? (
        <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
          <h2 className="text-xl font-semibold">Something went wrong</h2>
          <p className="text-muted-foreground text-sm">
            {this.state.error?.message}
          </p>
          <Button onClick={() => this.setState({ hasError: false, error: null })}>
            Try again
          </Button>
        </div>
      );
    }
    return this.props.children;
  }
}
```

---

## 6.8 Structured Logging Setup

```typescript
// src/lib/logger.ts
import pino from "pino";

export const logger = pino({
  level: process.env.LOG_LEVEL || "info",
  ...(process.env.NODE_ENV === "development"
    ? {
        transport: {
          target: "pino-pretty",
          options: { colorize: true, translateTime: "HH:MM:ss" },
        },
      }
    : {}),
  base: { env: process.env.NODE_ENV, service: "api" },
  redact: ["body.password", "body.token", "headers.authorization"],
});

// Request logger middleware
export const requestLogger = (req: any, res: any, next: any) => {
  const start = Date.now();
  res.on("finish", () => {
    logger.info({
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration: `${Date.now() - start}ms`,
      ip: req.ip,
    });
  });
  next();
};
```
