# 1. BASE
FROM node:22.12-alpine AS base
RUN apk add --no-cache libc6-compat
WORKDIR /app

# 2. DEPENDENCIES
FROM base AS deps
COPY package.json package-lock.json* ./
RUN npm ci

# 3. BUILDER
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Set Next.js to standalone mode for smaller production images
ENV NEXT_PRIVATE_STANDALONE=true
RUN npm run build

# 4. PRODUCTION RUNNER
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs

# Only copy what is needed for the standalone server
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Install sharp for image optimization (essential for Next.js <Image />)
# RUN npm install sharp

USER nextjs
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]