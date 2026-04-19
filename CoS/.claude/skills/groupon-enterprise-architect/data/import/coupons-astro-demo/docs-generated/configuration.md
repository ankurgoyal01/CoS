---
service: "coupons-astro-demo"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values]
---

# Configuration

## Overview

`coupons-astro-demo` is configured entirely through environment variables. There is no runtime config file loading, no Consul, and no Vault integration visible in the codebase. Deployment-time configuration is supplied via Helm values files (`.meta/deployment/cloud/components/app/`) that inject environment variables into the Kubernetes pods.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `REDIS_HOST` | Hostname of the Redis instance to connect to | yes | `localhost` | env / helm |
| `REDIS_PORT` | Port of the Redis instance | no | `6379` | env |
| `REDIS_PASSWORD` | Password for Redis authentication | no | _(none)_ | env / k8s-secret |
| `REDIS_DB` | Redis database index to use | no | `0` | env |
| `COUNTRY_CODE` | Two-letter country code used as part of the Redis key prefix (e.g., `US`, `GB`) | no | `US` | env / helm |
| `LOCALE_CODE` | Locale code used as part of the Redis key prefix (e.g., `en_US`, `en_GB`) | no | `en_US` | env / helm |
| `NODE_ENV` | Node.js environment mode | no | `production` (set in Dockerfile) | env / Dockerfile |
| `HOST` | Host address the Node.js server binds to | no | `0.0.0.0` (set in Dockerfile) | env / Dockerfile |
| `PORT` | Port the Node.js server listens on inside the container | no | `4321` (set in Dockerfile) | env / Dockerfile |
| `DEPLOYMENT_ENV` | Deployment environment label (e.g., `Conveyor_Cloud`) | no | _(none)_ | helm (staging override) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are recorded here.

## Feature Flags

> No evidence found in codebase. No feature flag system is integrated.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment config: service ID, Docker image, scaling (2–15 replicas), HTTP port (8080), admin port (8081) |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging environment overrides: GCP provider, `us-central1` region, `REDIS_HOST` pointing to Cloud Memorystore, scaling (1–2 replicas) |
| `astro.config.mjs` | ESM JS | Astro framework config: SSR output mode, Node.js standalone adapter, server host/port, Tailwind Vite plugin |
| `.nvmrc` | Text | Node.js version pin: `v22.14.0` |
| `.deploy_bot.yml` | YAML | Deploybot pipeline config: staging Kubernetes target, cluster, and deployment command |
| `Jenkinsfile` | Groovy DSL | Jenkins CI pipeline: Docker build, publish, and deploy to `staging-us-central1` on the `main` branch |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `REDIS_PASSWORD` | Redis authentication credential | k8s-secret (injected as env var) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Local development**: `REDIS_HOST` defaults to `localhost`; `REDIS_PORT` to `6379`. Run `pnpm dev` to start the Astro dev server on port `4321`.
- **Staging (GCP us-central1)**: `REDIS_HOST` is set to `coupon-worker-memorystore.us-central1.caches.stable.gcp.groupondev.com` via the staging helm values file; scaling reduced to 1–2 replicas; `DEPLOYMENT_ENV` is set to `Conveyor_Cloud`.
- **Production**: No production helm values file is present in the repository at time of generation. Production configuration is expected to follow the same pattern with a production Redis host and higher replica counts (up to 15 per the common config).
