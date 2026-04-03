# UNIT 1 — INSTANT THANOS PROMPT TEMPLATES

---

## The THANOS Prompt Formula

```
T — Task        (What exactly needs to be built/done)
H — Handle      (Tech stack, framework, language)
A — Assumptions (Constraints, existing code context)
N — Needs       (Output format: file, snippet, command)
O — Optimize    (Performance, security, scalability concern)
S — Style       (Code style, patterns, conventions)
```

---

## 1.1 Full Stack Feature Generator Prompt

```
You are a senior full stack engineer.

T: Build a [FEATURE_NAME] feature
H: Stack: Next.js 14 App Router + TypeScript + Prisma + PostgreSQL + Tailwind CSS
A: - Auth is already implemented via NextAuth.js
   - Prisma client is initialized at lib/prisma.ts
   - API routes use the pattern: app/api/[resource]/route.ts
N: Generate:
   1. Prisma schema addition (add to existing schema.prisma)
   2. API route handler (app/api/[resource]/route.ts)
   3. Server Action (app/actions/[feature].ts)
   4. React component (components/[Feature].tsx)
   5. Custom hook (hooks/use[Feature].ts)
O: - Use optimistic updates in the UI
   - Add proper error handling and loading states
   - Include Zod validation on all inputs
S: - Use named exports
   - TypeScript strict mode
   - No 'any' types
   - Use async/await, not .then()

Feature to build: [DESCRIBE FEATURE IN 2-3 SENTENCES]
```

---

## 1.2 Bug Fix Prompt Template

```
You are a senior debugger. Fix this bug precisely.

CONTEXT:
- Framework: [Next.js / Express / NestJS / etc.]
- Node version: [version]
- Error message: [PASTE FULL ERROR]
- File: [filename and path]

BROKEN CODE:
```[language]
[PASTE CODE HERE]
```

EXPECTED BEHAVIOR: [What it should do]
ACTUAL BEHAVIOR: [What it does]

RECENT CHANGES: [What changed before the bug appeared]

OUTPUT:
1. Root cause (one sentence)
2. Fixed code (full function/component, not just the changed line)
3. How to prevent this bug in future (one line)
Do not explain theory. Just fix it.
```

---

## 1.3 Code Review Prompt

```
You are a principal engineer doing a code review.

REVIEW THIS CODE:
```[language]
[PASTE CODE]
```

STACK: [Framework + language]
PR CONTEXT: [What this PR is supposed to do]

REVIEW FOR:
- [ ] Security vulnerabilities (SQL injection, XSS, auth bypass)
- [ ] Performance issues (N+1 queries, missing indexes, memory leaks)
- [ ] TypeScript type safety
- [ ] Error handling gaps
- [ ] Race conditions
- [ ] Missing edge cases

OUTPUT FORMAT:
For each issue found:
SEVERITY: [Critical/High/Medium/Low]
LINE: [line number or function name]
ISSUE: [one line description]
FIX:
```[language]
[corrected code]
```

Only report real issues. Do not report style preferences.
```

---

## 1.4 Architecture Decision Prompt

```
You are a solutions architect. Give me a decision, not options.

PROJECT: [Describe the project in 3 sentences]
SCALE: [Expected users/requests per day]
TEAM SIZE: [Number of developers]
TIMELINE: [Weeks to launch]
BUDGET: [Hosting budget/month]

DECIDE:
1. Frontend framework (and why in 10 words)
2. Backend framework (and why in 10 words)
3. Database choice (and why in 10 words)
4. Auth solution (and why in 10 words)
5. Hosting/deployment (and why in 10 words)
6. File storage (and why in 10 words)

Then generate:
- Folder structure (tree format)
- package.json dependencies list
- docker-compose.yml for local dev
- .env.example with all required vars

Do not hedge. Pick one option and justify it.
```

---

## 1.5 API Design Prompt

```
You are a REST API architect.

RESOURCE: [Resource name, e.g., "orders"]
ENTITY FIELDS: [List all fields]
AUTH: JWT Bearer token required
STACK: Express.js + TypeScript + Prisma + PostgreSQL

GENERATE:
1. Prisma model
2. Zod validation schemas (create, update, query)
3. Express router with all CRUD endpoints:
   GET    /api/[resource]          - list with pagination + filters
   GET    /api/[resource]/:id      - single item
   POST   /api/[resource]          - create
   PUT    /api/[resource]/:id      - full update
   PATCH  /api/[resource]/:id      - partial update
   DELETE /api/[resource]/:id      - soft delete
4. Controller functions (separate file)
5. Service layer (business logic separate from controller)
6. Middleware: auth check, input validation, error handling

REQUIREMENTS:
- Consistent error response format: { success, message, data, errors }
- Pagination: { page, limit, total, totalPages }
- Soft delete: add deletedAt field, filter in all queries
- Include request/response TypeScript types
```

---

## 1.6 Database Schema Prompt

```
You are a database architect.

PROJECT TYPE: [SaaS / E-commerce / Social / Blog / etc.]
CORE ENTITIES: [List all main entities]
RELATIONSHIPS: [Describe how entities relate]
DATABASE: PostgreSQL
ORM: Prisma

GENERATE:
1. Complete schema.prisma file with:
   - All models
   - Proper relations (1:1, 1:N, M:N with explicit join tables)
   - Indexes on foreign keys and frequently queried fields
   - Enums for status fields
   - createdAt, updatedAt, deletedAt on all models
   - UUID primary keys

2. Migration SQL (raw SQL for the initial migration)

3. Seed script (seed.ts) with realistic test data

4. Query examples for the 5 most common operations

CONSTRAINTS:
- No nullable fields unless absolutely required
- All M:N relations through explicit join tables
- Row-level security consideration comments
```

---

## 1.7 Security Audit Prompt

```
You are a security engineer. Audit this code for vulnerabilities.

CODE TO AUDIT:
```[language]
[PASTE CODE]
```

STACK: [Framework + database]

CHECK FOR:
1. SQL/NoSQL injection
2. XSS vulnerabilities
3. CSRF missing protection
4. Broken authentication
5. Sensitive data exposure (passwords, tokens in logs/responses)
6. Missing rate limiting
7. Insecure direct object reference (IDOR)
8. Missing input sanitization
9. Dependency vulnerabilities (list any risky patterns)
10. Secrets hardcoded in code

FOR EACH VULNERABILITY:
- Vulnerability type
- Exact location in code
- Exploit scenario (one sentence)
- Fix (show corrected code)

Severity: Critical > High > Medium > Low
List Critical and High first.
```

---

## 1.8 Refactor Prompt

```
You are a senior engineer refactoring legacy code.

CURRENT CODE:
```[language]
[PASTE CODE]
```

PROBLEMS WITH CURRENT CODE: [List what's wrong]
TARGET: [What good looks like — e.g., "clean, typed, tested, no duplication"]
CONSTRAINTS:
- Keep the same external API/interface
- Do not change behavior
- Target: [framework/pattern you want, e.g., "Repository pattern + Service layer"]

DELIVER:
1. Refactored code (complete files, not diffs)
2. What changed (bullet list, max 10 items)
3. Any follow-up refactors recommended (max 3)

Do not explain patterns. Just show the refactored code.
```

---

## 1.9 Documentation Generator Prompt

```
You are a technical writer. Generate developer docs only.

CODE:
```[language]
[PASTE CODE]
```

GENERATE:
1. JSDoc/TSDoc comments for every exported function/class
2. README.md section for this module:
   - What it does (1 sentence)
   - Installation/setup (commands only)
   - Usage examples (code blocks only, 3 examples minimum)
   - API reference table (function | params | returns | throws)
3. OpenAPI 3.0 spec (YAML) if this is an API route

FORMAT: Paste-ready markdown. No prose explanation. Just the docs.
```

---

## 1.10 Component Generator Prompt

```
You are a React/Next.js expert.

COMPONENT: [Name and purpose]
STACK: Next.js 14 + TypeScript + Tailwind CSS + shadcn/ui
DATA: [Describe props or data this component needs]
BEHAVIOR: [User interactions and state changes]
ACCESSIBILITY: WCAG 2.1 AA required

GENERATE:
1. TypeScript interface for props
2. Component file (components/[Name].tsx) — full implementation
3. Custom hook if stateful (hooks/use[Name].ts)
4. Unit test (components/[Name].test.tsx) using Testing Library
5. Storybook story ([Name].stories.tsx)

REQUIREMENTS:
- No inline styles
- Tailwind classes only
- Proper loading and error states
- Keyboard navigable
- Mobile responsive
```

---

## 1.11 Batch Prompt — Generate Entire Feature in One Shot

```
You are a full stack engineer. Build this entire feature end-to-end.

FEATURE: [Feature name]
APP CONTEXT: [Brief description of the app]
STACK:
  Frontend: Next.js 14 App Router + TypeScript + Tailwind + shadcn/ui + React Query
  Backend:  Node.js + Express + TypeScript + Prisma + PostgreSQL
  Auth:     JWT (access + refresh tokens)
  Cache:    Redis

GENERATE ALL FILES:

--- BACKEND ---
prisma/schema.prisma        (add [Feature] model)
src/routes/[feature].ts     (Express router)
src/controllers/[feature].ts
src/services/[feature].ts
src/validators/[feature].ts (Zod schemas)
src/middleware/auth.ts       (if not exists)

--- FRONTEND ---
app/[feature]/page.tsx
app/[feature]/[id]/page.tsx
components/[Feature]List.tsx
components/[Feature]Form.tsx
hooks/use[Feature].ts        (React Query hooks)
lib/api/[feature].ts         (API client functions)
types/[feature].ts

--- SHARED ---
.env.example additions
Database migration SQL

Output each file with its path as a comment at the top.
Complete implementations. No TODOs or placeholder comments.
```
