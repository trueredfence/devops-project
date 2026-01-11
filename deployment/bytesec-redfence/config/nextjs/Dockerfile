# 1. BASE
FROM node:22.12-alpine AS base
RUN apk add --no-cache libc6-compat openssl wget
WORKDIR /app

# 2. DEPENDENCIES
FROM base AS deps
COPY package.json package-lock.json* ./
RUN npm ci

# 3. BUILDER
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ARG NEXT_PUBLIC_BETTER_AUTH_URL
ENV NEXT_PUBLIC_BETTER_AUTH_URL=$NEXT_PUBLIC_BETTER_AUTH_URL
RUN npm run build

# 4. PRODUCTION RUNNER
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs

# Standalone build artifacts
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Critical for image optimization in production
RUN npm install sharp

# Hostname and port
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]

# 5. MIGRATION STAGE
FROM base AS migration_runner
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/drizzle ./drizzle
COPY --from=builder /app/drizzle.config.ts ./drizzle.config.ts
COPY --from=builder /app/package.json ./package.json