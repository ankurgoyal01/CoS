---
service: "ckod-ui"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, deployment-yaml, next-config]
---

# Configuration

## Overview

ckod-ui is configured primarily through environment variables. Client-accessible variables use the `NEXT_PUBLIC_` prefix (baked into the JS bundle at build time or injected at runtime via `next-runtime-env`). Server-side-only variables hold database connection strings and external API credentials. Default values for public variables are defined in `next.config.ts`. Per-environment overrides are declared in `.meta/deployment/cloud/components/app/` YAML files and applied by the Conveyor deployment platform.

## Environment Variables

### Public (Client + Server)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NEXT_PUBLIC_CKOD_API_BASE_URL` | Base URL for external-facing API calls | yes | `https://localhost:9000` | deployment YAML / `next.config.ts` |
| `NEXT_PUBLIC_CKOD_UI_URL` | Internal API base URL used by RTK Query (`ckodApi`) | yes | `http://localhost:8080/api` | deployment YAML / `next.config.ts` |
| `NEXT_PUBLIC_CONSUMER_AIRFLOW_BASE_URL` | Consumer Airflow UI base URL (linked from dashboards) | yes | Composer URL (central1) | deployment YAML / `next.config.ts` |
| `NEXT_PUBLIC_PIPELINES_AIRFLOW_BASE_URL` | Pipelines Airflow UI base URL | yes | Composer URL (central1) | deployment YAML / `next.config.ts` |
| `NEXT_PUBLIC_MDS_FEEDS_API_SWAGGER_URL` | Swagger URL for the MDS Feeds API | no | MDS Feeds production Swagger URL | deployment YAML / `next.config.ts` |
| `NEXT_PUBLIC_GITHUB_REPO_URL` | GitHub URL for ckod-ui repo (used in build info links) | no | `https://github.groupondev.com/PRE/ckod-ui` | `next.config.ts` |
| `NEXT_PUBLIC_COMMIT_HASH` | Git commit SHA embedded at build time | no | Resolved from `git rev-parse HEAD` | Dockerfile `ARG` / `next.config.ts` |
| `NEXT_PUBLIC_BUILD_DATE` | ISO 8601 build timestamp embedded at build time | no | `new Date().toISOString()` | Dockerfile `ARG` / `next.config.ts` |
| `NEXT_PUBLIC_BUILD_VERSION` | Build version tag or `{branch}-{buildNumber}` | no | `local-{branch}` | Dockerfile `ARG` / `next.config.ts` |
| `NEXT_PUBLIC_BUILD_BRANCH` | Git branch name embedded at build time | no | Resolved from `git rev-parse --abbrev-ref HEAD` | Dockerfile `ARG` / `next.config.ts` |

### Server-side Only

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `CKOD_DB_RO` | MySQL read-only connection string for `prismaRO` client | yes | none | k8s secret / vault |
| `CKOD_DB_RW` | MySQL read-write connection string for `prismaRW` client | yes | none | k8s secret / vault |
| `CKOD_SUPER_TOKEN` | Super-user token for headless / service-account access (checked against `ckod-token` header) | no | none | k8s secret |
| `CKOD_AGENTS_JSON` | JSON array of Vertex AI agent configurations (agentId, projectId, displayName, credentialsEnvKey, optional teams) | yes (for AI feature) | none | k8s secret / env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase of a formal feature flag system. Features are controlled by the presence of environment variables (e.g., `CKOD_AGENTS_JSON` enables the AI agent feature; `CKOD_SUPER_TOKEN` enables super-user access).

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `next.config.ts` | TypeScript | Next.js build configuration; defines `env` block with default values for all `NEXT_PUBLIC_*` variables |
| `prisma/schema.prisma` | Prisma DSL | Database schema definition for both MySQL stores |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Conveyor deployment config (replicas, resources, ports, log config) |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging environment overrides (env vars, VIP, region) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production (us-central1) environment overrides |
| `.meta/deployment/cloud/components/app/production-us-west-1.yml` | YAML | Production (us-west-1) environment overrides |
| `.deploy_bot.yml` | YAML | Deploybot pipeline target definitions (staging → production promotion) |
| `Jenkinsfile` | Groovy | Jenkins CI pipeline using `dockerBuildPipeline` shared library |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `CKOD_DB_RO` | Read-only MySQL DSN | k8s secret |
| `CKOD_DB_RW` | Read-write MySQL DSN | k8s secret |
| `CKOD_SUPER_TOKEN` | Super-user bypass token | k8s secret |
| `CKOD_AGENTS_JSON` | Vertex AI agent configs including credential env key references | k8s secret |

> Secret values are NEVER documented.

## Per-Environment Overrides

| Variable | Staging | Production (us-central1) |
|----------|---------|--------------------------|
| `NEXT_PUBLIC_CKOD_API_BASE_URL` | `https://dataops-staging.groupondev.com/api` | `https://dataops.groupondev.com/api` |
| `NEXT_PUBLIC_CKOD_UI_URL` | `https://dataops-staging.groupondev.com/api` | `https://dataops.groupondev.com/api` |
| `NEXT_PUBLIC_PIPELINES_AIRFLOW_BASE_URL` | Staging Composer URL | Production Composer URL |
| `NEXT_PUBLIC_CONSUMER_AIRFLOW_BASE_URL` | Staging Composer URL | Production Composer URL |
| `NEXT_PUBLIC_MDS_FEEDS_API_SWAGGER_URL` | `mds-feed.staging.service.us-central1...` | `mds-feed.production.service.us-central1...` |
| `PORT` | `8080` | `8080` |
| VIP hostname | `ckod-ui.staging.service.us-central1.gcp.groupondev.com` | `ckod-ui.production.service.us-central1.gcp.groupondev.com` |
| Replicas (min/max) | 1 / 2 | 1 / 2 (common: 2 / 15) |
