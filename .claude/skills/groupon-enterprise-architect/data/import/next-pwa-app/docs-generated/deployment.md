---
service: "next-pwa-app"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging", "production"]
---

# Deployment

## Overview

next-pwa-app is deployed as a Docker container running Next.js in standalone mode, managed by the `wattpm` process manager (Platformatic). The multi-stage Docker build produces a minimal runtime image. Deployment is orchestrated via Napistrano/Conveyor (Groupon's internal deployment platform) on Kubernetes. The application listens on port 8000 and exposes a metrics endpoint on port 9090.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Multi-stage build, `Dockerfile` at repo root |
| Base image | `docker-conveyor.groupondev.com/mobile-next/next-pwa-release-base-node22` | Custom Node 22 base image |
| Process manager | wattpm (Platformatic) | `apps/next-pwa/watt.json` -- manages workers, logging, metrics |
| Orchestration | Kubernetes (via Napistrano/Conveyor) | ITier service mesh |
| Load balancer | Akamai CDN + ITier routing | CDN for static assets, ITier for API routing |
| CDN | Akamai | Static asset delivery, configurable via `assetPrefix` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production testing, auto-deploy on main merge | us-west-1 | `next-pwa-app.staging.service.us-west-1.aws.groupondev.com` |
| Production | Consumer-facing traffic | us-central1 (GCP) | `www.groupon.com` (behind Akamai) |

## CI/CD Pipeline

### GitHub Actions (Primary CI)

- **Tool**: GitHub Actions
- **Config**: `.github/workflows/ci.yml` (orchestrator)
- **Trigger**: Push to `main`, Pull request events (opened, synchronize, reopened)

#### Pipeline Stages

1. **Lint** (`.github/workflows/lint.yml`): ESLint and Biome formatting checks
2. **Type Check** (`.github/workflows/typecheck.yml`): TypeScript type checking with codegen
3. **Unit Tests** (`.github/workflows/test.yml`): Jest unit tests (runs after lint + typecheck)
4. **Docker Build** (`.github/workflows/docker-build.yml`): Container image build and push
5. **Build** (`.github/workflows/build.yml`): Next.js production build
6. **Component Tests** (`.github/workflows/component-tests.yml`): Storybook component tests

#### Optional (PR comment-triggered)

- **Web E2E** (`.github/workflows/web-e2e-command.yml`): Playwright end-to-end tests via `/web-e2e` command
- **Mobile E2E** (`.github/workflows/mobile-e2e-command.yml`): Detox mobile tests via `/mobile-e2e` command
- **Happo** (`.github/workflows/happo-command.yml`): Visual regression testing via `/happo` command
- **Deploy** (`.github/workflows/deploy-command.yml`): Manual deployment trigger via `/deploy` command
- **CWV Test** (`.github/workflows/cwv-test-command.yml`): Core Web Vitals testing
- **Storybook Deploy** (`.github/workflows/deploy-storybook.yml`): Storybook static site deployment

### Jenkins (Build & Deploy)

- **Tool**: Jenkins (itier-pipeline-dsl)
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: GitHub webhooks on push to main and PR branches
- **Purpose**: Production build, Docker image creation, and deployment via Napistrano/Conveyor

#### Jenkins Pipeline Stages

1. **Install**: `bun install --frozen-lockfile`
2. **Codegen**: GraphQL type generation
3. **Build**: `bun run build:standalone` (Next.js standalone output via Turbopack)
4. **GPT Embed Build**: Separate LLM-embeddable widget build
5. **Post-build**: MaxMind DB download, ratings update, asset distribution, asset upload
6. **Docker**: Multi-stage build producing minimal runtime image
7. **Deploy**: Napistrano deployment to staging/production

## Docker Build Process

The Dockerfile uses a two-stage approach:

1. **Builder stage**: Installs dependencies with bun, runs codegen, builds Next.js in standalone mode, builds gpt-embed, downloads MaxMind GeoIP DB, and uploads static assets
2. **Runtime stage**: Copies only the standalone output directory, SHA file, and MaxMind DB into a clean base image

```
EXPOSE 8000
CMD ["node", "../../node_modules/wattpm/bin/cli.js", "start"]
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA / Napistrano scaling | Managed by ITier ops |
| Workers | wattpm static workers | `WATT_WORKERS` env var (default: 1) |
| Memory | Node.js max-old-space-size | 12GB for builds, runtime defaults |
| Build parallelism | Nx parallel execution | `NX_PARALLEL=1` in Docker (resource-constrained) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Managed by Kubernetes | Managed by Kubernetes |
| Memory | Managed by Kubernetes | Build: 12GB (`--max-old-space-size=12000`) |
| Disk | Minimal (standalone output ~100MB + MaxMind DB) | -- |

## Labels

The Docker image carries ITier-standard labels:
- `com.groupon.conveyor.app.service-id`: `next-pwa-app::itier`
- `com.groupon.conveyor.app.type`: `itier`
- `com.groupon.conveyor.app.name`: `next-pwa-app`
- `com.groupon.conveyor.app.logstash.sourcetypes`: `tracky=tracky.log.*`
