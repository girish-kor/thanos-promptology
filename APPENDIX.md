# APPENDIX — EXTRA SCRIPTS, CONFIG TEMPLATES & REUSABLE PATTERNS

---

## A.1 TypeScript Config Templates

```json
// tsconfig.base.json (shared across monorepo)
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noEmit": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "moduleResolution": "bundler",
    "module": "ESNext",
    "target": "ES2022",
    "lib": ["ES2022"],
    "resolveJsonModule": true
  }
}
```

```json
// apps/web/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "jsx": "preserve",
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

---

## A.2 ESLint Config

```javascript
// eslint.config.mjs
import { FlatCompat } from "@eslint/eslintrc";
import js from "@eslint/js";
import tsParser from "@typescript-eslint/parser";
import tsPlugin from "@typescript-eslint/eslint-plugin";

const compat = new FlatCompat({ baseDirectory: import.meta.dirname });

export default [
  js.configs.recommended,
  ...compat.extends("next/core-web-vitals"),
  {
    files: ["**/*.ts", "**/*.tsx"],
    languageOptions: { parser: tsParser },
    plugins: { "@typescript-eslint": tsPlugin },
    rules: {
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "@typescript-eslint/consistent-type-imports": "error",
      "no-console": ["warn", { allow: ["warn", "error"] }],
    },
  },
  { ignores: ["node_modules", ".next", "dist", "coverage"] },
];
```

---

## A.3 Prettier Config

```json
// .prettierrc
{
  "semi": true,
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "plugins": [
    "prettier-plugin-tailwindcss",
    "@trivago/prettier-plugin-sort-imports"
  ],
  "importOrder": [
    "^react",
    "^next",
    "<THIRD_PARTY_MODULES>",
    "^@/(.*)$",
    "^[./]"
  ],
  "importOrderSeparation": true
}
```

---

## A.4 Error Handler Middleware (Express)

```typescript
// src/middleware/errorHandler.ts
import type { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import { Prisma } from "@prisma/client";
import { logger } from "../lib/logger";

export function errorHandler(
  error: Error,
  req: Request,
  res: Response,
  _next: NextFunction
) {
  logger.error({ error, url: req.url, method: req.method }, "Request error");

  // Zod validation error
  if (error instanceof ZodError) {
    return res.status(400).json({
      success: false,
      message: "Validation failed",
      errors: error.flatten().fieldErrors,
    });
  }

  // Prisma unique constraint
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === "P2002") {
      return res.status(409).json({
        success: false,
        message: `${(error.meta?.target as string[])?.[0] ?? "Field"} already exists`,
      });
    }
    if (error.code === "P2025") {
      return res.status(404).json({ success: false, message: "Record not found" });
    }
  }

  // Custom app errors
  if ("statusCode" in error) {
    return res.status((error as any).statusCode).json({
      success: false,
      message: error.message,
    });
  }

  // Default 500
  res.status(500).json({
    success: false,
    message: process.env.NODE_ENV === "production"
      ? "Internal server error"
      : error.message,
  });
}

// Custom error class
export class AppError extends Error {
  constructor(message: string, public statusCode = 400) {
    super(message);
    this.name = "AppError";
  }
}
```

---

## A.5 Reusable Prompt Patterns

### Pattern: "Add X to existing Y"

```
Add [FEATURE] to this existing [STACK] application.

Existing code:
[PASTE RELEVANT FILES]

Add:
- [specific addition 1]
- [specific addition 2]

Constraints:
- Do NOT change existing interfaces/APIs
- Maintain backward compatibility
- Follow existing code patterns (naming, structure)

Output: Only new/modified files. Start each with // FILE: path
```

### Pattern: "Migrate from X to Y"

```
Migrate this codebase from [SOURCE_TECH] to [TARGET_TECH].

Current: [paste code]

Target tech: [framework/library/pattern]

Migration steps:
1. [step]
2. [step]

Generate:
- New implementation
- Migration script if needed (for data)
- Updated package.json dependencies

Do NOT change behavior. Only change the implementation.
```

### Pattern: "Scale this for production"

```
Make this production-ready. Current state: [paste code or describe]

Add:
- Error handling (try/catch, proper HTTP codes)
- Input validation (Zod schemas)
- Authentication check
- Rate limiting
- Logging (pino)
- Caching (Redis, TTL: [X] seconds)
- Database indexes (Prisma @@index)

Performance target: p95 < 200ms
Show complete updated files.
```

---

## A.6 Nginx Config

```nginx
# /etc/nginx/conf.d/app.conf
upstream api_backend {
  server localhost:3001;
  keepalive 32;
}

server {
  listen 80;
  server_name api.yourdomain.com;
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl http2;
  server_name api.yourdomain.com;

  ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

  # Gzip
  gzip on;
  gzip_types application/json text/plain application/javascript;

  # Security headers
  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;
  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";

  # Rate limiting
  limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;

  location / {
    limit_req zone=api burst=20 nodelay;
    proxy_pass http://api_backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
    proxy_read_timeout 60s;
    proxy_connect_timeout 10s;
  }

  # WebSocket
  location /socket.io/ {
    proxy_pass http://api_backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
  }
}
```

---

## A.7 Database Backup Script

```bash
#!/bin/bash
# scripts/backup-db.sh

set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"
DB_NAME="${POSTGRES_DB:-myapp}"
S3_BUCKET="${S3_BACKUP_BUCKET:-myapp-backups}"

mkdir -p $BACKUP_DIR

# Create backup
echo "📦 Creating backup..."
PGPASSWORD=$POSTGRES_PASSWORD pg_dump \
  -h $POSTGRES_HOST \
  -U $POSTGRES_USER \
  -d $DB_NAME \
  --verbose \
  --no-owner \
  --no-acl \
  -f "$BACKUP_DIR/$DB_NAME-$TIMESTAMP.sql"

# Compress
gzip "$BACKUP_DIR/$DB_NAME-$TIMESTAMP.sql"

# Upload to S3
aws s3 cp "$BACKUP_DIR/$DB_NAME-$TIMESTAMP.sql.gz" \
  "s3://$S3_BUCKET/postgres/$DB_NAME-$TIMESTAMP.sql.gz" \
  --storage-class STANDARD_IA

# Cleanup local backups older than 7 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "✅ Backup uploaded: s3://$S3_BUCKET/postgres/$DB_NAME-$TIMESTAMP.sql.gz"
```

---

## A.8 Health Check Endpoint

```typescript
// src/routes/health.ts
import { Router } from "express";
import { prisma } from "../lib/db";
import { redis } from "../lib/redis";

const router = Router();

router.get("/health", async (req, res) => {
  const checks: Record<string, boolean> = {};

  // DB check
  try {
    await prisma.$queryRaw`SELECT 1`;
    checks.database = true;
  } catch {
    checks.database = false;
  }

  // Redis check
  try {
    await redis.ping();
    checks.redis = true;
  } catch {
    checks.redis = false;
  }

  const healthy = Object.values(checks).every(Boolean);
  const status = healthy ? 200 : 503;

  res.status(status).json({
    status: healthy ? "ok" : "degraded",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    checks,
    version: process.env.npm_package_version,
  });
});

export default router;
```
