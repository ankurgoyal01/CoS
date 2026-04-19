---
service: "coffee-to-go"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging-us-central1"]
---

# Deployment

## Overview

Coffee To Go is deployed as a single Docker container that bundles both the Express API backend and the pre-built React frontend (served as static files from the API's `public` directory). The container is built using a multi-stage Dockerfile and deployed via Jenkins to a staging environment in GCP `us-central1`. The base image is `node:22-alpine` from Groupon's internal Docker registry.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Multi-stage Dockerfile at repo root (`Dockerfile`) |
| Base image | node:22-alpine | `docker.groupondev.com/node:22-alpine` |
| Orchestration | Kubernetes (inferred) | Deployed via Jenkins `dockerBuildPipeline` to `staging-us-central1` |
| CI/CD | Jenkins | `Jenkinsfile` at repo root |

## Build Process

The multi-stage Docker build performs:

1. **deps**: Install production dependencies for the API (`npm ci --only=production`)
2. **deps-dev**: Install all dependencies including dev dependencies for both API and React app
3. **build**: Run linting (`npm run lint`), API type checking (`npm run build`), React tests with coverage (`npm run test:coverage`), React production build (`npm run build`), and copy built assets to the API's `public` directory
4. **production**: Create a non-root `appuser`, copy production dependencies, API source, common package, React config files, and built React assets. Run as `appuser` on port 3000.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development | Local | `http://localhost:8080` (React), `http://localhost:3000` (API) |
| Staging | Pre-production testing | GCP us-central1 | Deployed via Jenkins |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Docker build pipeline (on push, inferred from `dockerBuildPipeline`)
- **Library**: `java-pipeline-dsl@latest-2`

### Pipeline Stages

1. **Lint**: Biome formatting and linting check across the monorepo
2. **API typecheck**: TypeScript compilation check for the API
3. **React test**: Run Vitest test suite with coverage
4. **React build**: Production build of the React app via Vite
5. **Docker build**: Multi-stage Docker image build
6. **Deploy**: Push to `staging-us-central1`

## Scaling

> No evidence found in codebase for auto-scaling configuration. Scaling parameters are likely managed externally in Kubernetes manifests or Helm charts.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Exposed port | 3000 | 3000 |
| Log volume | `/var/groupon/logs` | Mounted for pino-roll log rotation (100MB per file, max 2 files) |

## Security

- The production container runs as a non-root user (`appuser`, UID 1001)
- `NODE_ENV=production` is set in the production stage
- Helmet middleware adds security headers
- CORS is configured to allow only the frontend origin
- Authentication restricts access to Groupon email domains only
- API key endpoints are disabled at the middleware level to prevent self-service key creation
- OAuth tokens (accessToken, idToken, refreshToken) are stripped before being stored in the database
