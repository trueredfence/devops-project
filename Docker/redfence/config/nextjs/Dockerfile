# 1. BASE
FROM node:22.12-alpine AS base
RUN apk add --no-cache libc6-compat openssl wget
WORKDIR /app

# 2. DEPENDENCIES
FROM base AS deps
COPY package.json package-lock.json* ./
# npm ci is faster and ensures exact versions from lockfile
RUN npm ci

# 3. BUILDER
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ARG NEXT_PUBLIC_BETTER_AUTH_URL
ENV NEXT_PUBLIC_BETTER_AUTH_URL=$NEXT_PUBLIC_BETTER_AUTH_URL
# Next.js standalone build is enabled in next.config.js
RUN npm run build

# 4. PRODUCTION RUNNER (The Tiny One)
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs

# Only copy what is strictly needed for the app to run
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]

# 5. MIGRATION RUNNER (The Utility One)
FROM base AS migration_runner
WORKDIR /app
ENV NODE_ENV=production

# Pro-Tip: We copy the FULL node_modules here because migrations need devDependencies (like drizzle-kit)
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/drizzle ./drizzle
COPY --from=builder /app/drizzle.config.ts ./drizzle.config.ts
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/src ./src

# Run as root to ensure npx has permission to execute binaries and access network
USER root