# UNIT 4 — BACKEND RAPID PROTOTYPING PROMPTS

---

## 4.1 CRUD Generator Prompt

```
Stack: Express.js + TypeScript + Prisma + PostgreSQL
Generate complete CRUD API for resource: [RESOURCE_NAME]

Fields: [field: type, field: type, ...]

Generate:
1. Prisma model (add to schema.prisma)
2. Zod schemas: createSchema, updateSchema, querySchema
3. src/routes/[resource].ts
4. src/controllers/[resource].controller.ts
5. src/services/[resource].service.ts

Patterns:
- Controller thin: only req/res handling + error catching
- Service fat: all business logic, DB calls
- Consistent response: { success, data, message, pagination? }
- Soft deletes: deletedAt field
- Pagination: ?page=1&limit=10
- Filter: ?search=term&status=active
- Sort: ?sortBy=createdAt&order=desc
```

### Express Router Template

```typescript
// src/routes/posts.ts
import { Router } from "express";
import { authenticate } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { createPostSchema, updatePostSchema, queryPostSchema } from "../validators/post";
import {
  getPosts, getPost, createPost, updatePost, deletePost,
} from "../controllers/post.controller";

const router = Router();

router.get("/", validate(queryPostSchema, "query"), getPosts);
router.get("/:id", getPost);
router.post("/", authenticate, validate(createPostSchema), createPost);
router.put("/:id", authenticate, validate(updatePostSchema), updatePost);
router.patch("/:id", authenticate, validate(updatePostSchema.partial()), updatePost);
router.delete("/:id", authenticate, deletePost);

export default router;
```

### Controller Template

```typescript
// src/controllers/post.controller.ts
import type { Request, Response } from "express";
import * as postService from "../services/post.service";
import { ApiResponse } from "../utils/apiResponse";

export const getPosts = async (req: Request, res: Response) => {
  const { page = 1, limit = 10, search, status, sortBy = "createdAt", order = "desc" } = req.query;

  const result = await postService.findMany({
    page: Number(page),
    limit: Number(limit),
    search: search as string,
    status: status as string,
    sortBy: sortBy as string,
    order: order as "asc" | "desc",
  });

  res.json(ApiResponse.paginated(result.posts, result.total, Number(page), Number(limit)));
};

export const getPost = async (req: Request, res: Response) => {
  const post = await postService.findById(req.params.id!);
  if (!post) return res.status(404).json(ApiResponse.error("Post not found", 404));
  res.json(ApiResponse.success(post));
};

export const createPost = async (req: Request, res: Response) => {
  const post = await postService.create({ ...req.body, authorId: req.user!.id });
  res.status(201).json(ApiResponse.success(post, "Post created"));
};

export const updatePost = async (req: Request, res: Response) => {
  const post = await postService.update(req.params.id!, req.body, req.user!.id);
  if (!post) return res.status(404).json(ApiResponse.error("Post not found", 404));
  res.json(ApiResponse.success(post, "Post updated"));
};

export const deletePost = async (req: Request, res: Response) => {
  await postService.softDelete(req.params.id!, req.user!.id);
  res.json(ApiResponse.success(null, "Post deleted"));
};
```

### Service Template

```typescript
// src/services/post.service.ts
import { prisma } from "../lib/db";
import type { Prisma } from "@prisma/client";

interface FindManyParams {
  page: number;
  limit: number;
  search?: string;
  status?: string;
  sortBy: string;
  order: "asc" | "desc";
}

export async function findMany({ page, limit, search, sortBy, order }: FindManyParams) {
  const skip = (page - 1) * limit;

  const where: Prisma.PostWhereInput = {
    deletedAt: null,
    ...(search && {
      OR: [
        { title: { contains: search, mode: "insensitive" } },
        { content: { contains: search, mode: "insensitive" } },
      ],
    }),
  };

  const [posts, total] = await Promise.all([
    prisma.post.findMany({
      where,
      skip,
      take: limit,
      orderBy: { [sortBy]: order },
      include: { author: { select: { id: true, name: true, email: true } } },
    }),
    prisma.post.count({ where }),
  ]);

  return { posts, total };
}

export const findById = (id: string) =>
  prisma.post.findFirst({
    where: { id, deletedAt: null },
    include: { author: { select: { id: true, name: true } } },
  });

export const create = (data: Prisma.PostCreateInput) =>
  prisma.post.create({ data });

export async function update(id: string, data: Partial<Prisma.PostUpdateInput>, userId: string) {
  const post = await prisma.post.findFirst({ where: { id, authorId: userId, deletedAt: null } });
  if (!post) return null;
  return prisma.post.update({ where: { id }, data: { ...data, updatedAt: new Date() } });
}

export async function softDelete(id: string, userId: string) {
  return prisma.post.updateMany({
    where: { id, authorId: userId, deletedAt: null },
    data: { deletedAt: new Date() },
  });
}
```

---

## 4.2 JWT Auth Implementation

```typescript
// src/middleware/auth.ts
import type { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { prisma } from "../lib/db";

interface JwtPayload { id: string; email: string; role: string; }

declare global {
  namespace Express {
    interface Request {
      user?: { id: string; email: string; role: string };
    }
  }
}

export const authenticate = async (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    return res.status(401).json({ success: false, message: "No token provided" });
  }

  try {
    const token = authHeader.slice(7);
    const payload = jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
    const user = await prisma.user.findFirst({
      where: { id: payload.id, deletedAt: null },
      select: { id: true, email: true, role: true },
    });
    if (!user) return res.status(401).json({ success: false, message: "User not found" });
    req.user = user;
    next();
  } catch {
    return res.status(401).json({ success: false, message: "Invalid token" });
  }
};

export const authorize = (...roles: string[]) =>
  (req: Request, res: Response, next: NextFunction) => {
    if (!roles.includes(req.user?.role ?? "")) {
      return res.status(403).json({ success: false, message: "Insufficient permissions" });
    }
    next();
  };
```

```typescript
// src/utils/apiResponse.ts
export class ApiResponse {
  static success<T>(data: T, message = "Success") {
    return { success: true, message, data };
  }

  static error(message: string, statusCode = 400, errors?: unknown) {
    return { success: false, message, errors };
  }

  static paginated<T>(data: T[], total: number, page: number, limit: number) {
    return {
      success: true,
      data,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page < Math.ceil(total / limit),
        hasPrevPage: page > 1,
      },
    };
  }
}
```

---

## 4.3 Validation Middleware

```typescript
// src/middleware/validate.ts
import type { Request, Response, NextFunction } from "express";
import type { ZodSchema } from "zod";

export const validate =
  (schema: ZodSchema, target: "body" | "query" | "params" = "body") =>
  (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req[target]);
    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: "Validation failed",
        errors: result.error.flatten().fieldErrors,
      });
    }
    req[target] = result.data;
    next();
  };
```

---

## 4.4 Auth Service — Login + Register + Refresh

```typescript
// src/services/auth.service.ts
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import { prisma } from "../lib/db";

const ACCESS_EXPIRY = "15m";
const REFRESH_EXPIRY = "7d";

function signAccess(id: string, email: string, role: string) {
  return jwt.sign({ id, email, role }, process.env.JWT_SECRET!, { expiresIn: ACCESS_EXPIRY });
}

function signRefresh(id: string) {
  return jwt.sign({ id }, process.env.JWT_REFRESH_SECRET!, { expiresIn: REFRESH_EXPIRY });
}

export async function register(name: string, email: string, password: string) {
  const exists = await prisma.user.findUnique({ where: { email } });
  if (exists) throw new Error("Email already in use");

  const hashed = await bcrypt.hash(password, 12);
  const user = await prisma.user.create({
    data: { name, email, password: hashed },
    select: { id: true, email: true, name: true, role: true },
  });

  const accessToken = signAccess(user.id, user.email, user.role);
  const refreshToken = signRefresh(user.id);
  return { user, accessToken, refreshToken };
}

export async function login(email: string, password: string) {
  const user = await prisma.user.findFirst({
    where: { email, deletedAt: null },
    select: { id: true, email: true, name: true, role: true, password: true },
  });

  if (!user || !user.password) throw new Error("Invalid credentials");

  const valid = await bcrypt.compare(password, user.password);
  if (!valid) throw new Error("Invalid credentials");

  const { password: _, ...safeUser } = user;
  const accessToken = signAccess(user.id, user.email, user.role);
  const refreshToken = signRefresh(user.id);
  return { user: safeUser, accessToken, refreshToken };
}

export async function refresh(refreshToken: string) {
  const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET!) as { id: string };
  const user = await prisma.user.findFirst({
    where: { id: payload.id, deletedAt: null },
    select: { id: true, email: true, role: true },
  });
  if (!user) throw new Error("User not found");
  return { accessToken: signAccess(user.id, user.email, user.role) };
}
```

---

## 4.5 Redis Caching Layer

```typescript
// src/lib/cache.ts
import { Redis } from "ioredis";

const redis = new Redis(process.env.REDIS_URL!);

export const cache = {
  async get<T>(key: string): Promise<T | null> {
    const val = await redis.get(key);
    return val ? (JSON.parse(val) as T) : null;
  },

  async set(key: string, value: unknown, ttlSeconds = 300) {
    await redis.setex(key, ttlSeconds, JSON.stringify(value));
  },

  async del(key: string) {
    await redis.del(key);
  },

  async delPattern(pattern: string) {
    const keys = await redis.keys(pattern);
    if (keys.length) await redis.del(...keys);
  },
};

// Cache decorator for service functions
export function withCache<T>(
  keyFn: (...args: unknown[]) => string,
  ttl = 300
) {
  return function (fn: (...args: unknown[]) => Promise<T>) {
    return async (...args: unknown[]): Promise<T> => {
      const key = keyFn(...args);
      const cached = await cache.get<T>(key);
      if (cached) return cached;
      const result = await fn(...args);
      await cache.set(key, result, ttl);
      return result;
    };
  };
}
```

---

## 4.6 File Upload Handler (Multer + Cloudinary)

```bash
npm install multer @types/multer cloudinary multer-storage-cloudinary
```

```typescript
// src/middleware/upload.ts
import multer from "multer";
import { v2 as cloudinary } from "cloudinary";
import { CloudinaryStorage } from "multer-storage-cloudinary";

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const storage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: "uploads",
    allowed_formats: ["jpg", "jpeg", "png", "gif", "webp", "pdf"],
    transformation: [{ width: 1200, crop: "limit" }],
  } as object,
});

export const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (_, file, cb) => {
    const allowed = ["image/jpeg", "image/png", "image/webp", "application/pdf"];
    allowed.includes(file.mimetype) ? cb(null, true) : cb(new Error("Invalid file type"));
  },
});

// Usage in routes:
// router.post('/upload', authenticate, upload.single('file'), uploadController);
// router.post('/upload-multiple', authenticate, upload.array('files', 10), uploadController);
```

---

## 4.7 Email Service (Nodemailer + Templates)

```typescript
// src/services/email.service.ts
import nodemailer from "nodemailer";

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || "localhost",
  port: Number(process.env.SMTP_PORT) || 1025,
  secure: false,
  auth: process.env.SMTP_USER
    ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
    : undefined,
});

interface EmailOptions {
  to: string;
  subject: string;
  html: string;
}

export async function sendEmail({ to, subject, html }: EmailOptions) {
  return transporter.sendMail({
    from: `"${process.env.APP_NAME}" <${process.env.FROM_EMAIL}>`,
    to,
    subject,
    html,
  });
}

export const templates = {
  welcome: (name: string) => `
    <h1>Welcome, ${name}!</h1>
    <p>Your account has been created successfully.</p>
  `,
  resetPassword: (link: string) => `
    <h1>Reset your password</h1>
    <p><a href="${link}">Click here to reset your password</a></p>
    <p>This link expires in 1 hour.</p>
  `,
  verifyEmail: (link: string) => `
    <h1>Verify your email</h1>
    <p><a href="${link}">Click here to verify your email</a></p>
  `,
};
```
