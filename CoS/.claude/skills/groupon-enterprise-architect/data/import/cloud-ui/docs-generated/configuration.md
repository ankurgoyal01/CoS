---
service: "cloud-ui"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, encore-secrets, helm-values]
---

# Configuration

## Overview

Cloud UI is configured through environment variables injected at container runtime. The Next.js frontend reads backend API URL from either `API_URL` (server-side) or `NEXT_PUBLIC_API_URL` (build-time public). The Cloud Backend (Encore) reads configuration via Encore's secret management system and standard environment variables. Deployment-environment values are provided via Helm values files under `.meta/deployment/cloud/`.

## Environment Variables

### Cloud UI Frontend (`continuumCloudUi`)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `API_URL` | Server-side backend API base URL; takes precedence over `NEXT_PUBLIC_API_URL` | No | `""` | env, Helm values |
| `NEXT_PUBLIC_API_URL` | Build-time public backend API base URL; used if `API_URL` is not set | No | `""` | env, Helm values |
| `NODE_ENV` | Node.js environment mode | No | `production` (Dockerfile) | env |
| `PORT` | HTTP port the Next.js server listens on | No | `3000` (Dockerfile) | env |
| `HOSTNAME` | Bind address for the Next.js server | No | `0.0.0.0` (Dockerfile) | env |
| `APP_VERSION` | Application version string returned by `/api/config` | No | `"unknown"` | env |

**URL resolution order** (as implemented in `app/api/config/route.ts`):
1. `API_URL` (server environment variable)
2. `NEXT_PUBLIC_API_URL` (build-time public variable)
3. `http://127.0.0.1:4000/cloud-backend` (hardcoded fallback for local development)

### Cloud Backend API (`continuumCloudBackendApi`)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENCORE_ENVIRONMENT` | Encore runtime environment name; read by health endpoint | No | `""` | env (Encore) |
| `ENVIRONMENT` | Fallback environment name for health endpoint | No | `"development"` | env |

## Feature Flags

> No evidence found in codebase. No feature flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML (Helm values) | Common deployment settings: `serviceId`, `appImage`, replica counts, health probe paths, lifecycle hooks |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML (Helm values) | Staging environment overrides: `cloudProvider`, `deployEnv`, `region`, `vpc`, `API_URL` env var injection |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML (Helm values) | Production environment overrides: `cloudProvider`, `deployEnv`, `region`, `vpc`, `API_URL` env var injection |
| `.meta/.raptor.yml` | YAML | Raptor component metadata: `serviceId: cloud-ui`, `component: app`, `type: api` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `CloudBackendGitSSHKey` | SSH private key content for Git clone/commit/push operations in the GitOps sync flow | Encore secret management (`encore secret set`) |

> Secret values are never documented. The secret name `CloudBackendGitSSHKey` is the Encore secret identifier. Set with: `encore secret set --type <env> CloudBackendGitSSHKey`.

## Per-Environment Overrides

| Environment | Key Difference |
|-------------|---------------|
| Local development | `NEXT_PUBLIC_API_URL=http://localhost:4000/cloud-backend`; backend runs via `encore run` on port 4000 |
| Staging (`staging-us-central1`) | `API_URL` set to Encore preview environment URL (`https://pr1022-groupon-encore-go-roni.encr.app/cloud-backend`); `cloudProvider: gcp`, `region: us-central1`, `vpc: stable` |
| Production (`production-us-central1`) | Same structural pattern as staging with production-appropriate `API_URL`; `deployEnv: staging` in the found file (likely a copy issue — production values should use `deployEnv: production`) |

**Common deployment defaults** (from `.meta/deployment/cloud/components/app/common.yml`):

| Setting | Value |
|---------|-------|
| `serviceId` | `cloud-ui` |
| `component` | `app` |
| `appImage` | `docker-conveyor.groupondev.com/conveyor-cloud/cloud-ui` |
| `minReplicas` | `2` |
| `maxReplicas` | `2` |
| `httpPort` | `3000` |
| Readiness probe path | `/api/health` |
| Liveness probe path | `/api/health` |
| Readiness probe port | `3000` |
| Liveness probe port | `3000` |
| Readiness delay | `10s` |
| Liveness delay | `10s` |
