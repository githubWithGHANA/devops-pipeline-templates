# syntax=docker/dockerfile:1
# Node.js application image (sanitized template).
# Build context: ./<app-dir>. Run tests in CI before building; the image build should not be the only test gate.

FROM node:22-alpine AS build
WORKDIR /build
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Adjust to your project: typecheck, test, build.
RUN npm run build

FROM node:22-alpine
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 --ingroup appgroup --shell /usr/sbin/nologin appuser
WORKDIR /app
COPY --from=build /build/package.json /build/package-lock.json ./
COPY --from=build /build/dist ./dist
USER appuser
ENV NODE_ENV=production
EXPOSE ${APP_PORT:-3000}
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:${APP_PORT}/health || exit 1
ENTRYPOINT ["node", "dist/main.js"]
