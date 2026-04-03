# @thanos/api

NestJS backend API for the Thanos Promptology project.

## Getting Started

```bash
pnpm dev
```

The API will start on [http://localhost:3001](http://localhost:3001).

## Project Structure

- `src/modules/` - Feature modules
- `src/common/` - Common filters, guards, interceptors
- `src/database/` - Database integration
- `src/config/` - Application configuration

## Scripts

- `pnpm dev` - Start dev server with hot reload
- `pnpm build` - Build for production
- `pnpm start` - Start production server
- `pnpm lint` - Run ESLint
- `pnpm test` - Run tests
- `pnpm test:cov` - Generate coverage report

## Dependencies

- NestJS 10
- JWT authentication
- Passport.js
- Class validation

## API Endpoints

### Health Check
- `GET /health` - Health status

### Authentication
- `POST /auth/register` - Register user
- `POST /auth/login` - Login user
- `POST /auth/refresh` - Refresh token

## Environment Variables

Create a `.env.local` file:

```env
NODE_ENV=development
PORT=3001
DATABASE_URL=postgresql://postgres:password@localhost:5432/thanos_db
JWT_SECRET=your_secret_here
```
