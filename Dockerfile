FROM node:20-alpine

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy monorepo
COPY . .

# Install dependencies
RUN pnpm install --frozen-lockfile

# Build
RUN pnpm build

# Set production env
ENV NODE_ENV=production

# Expose port
EXPOSE 3001

# Start API
CMD ["pnpm", "--filter", "api", "start"]
