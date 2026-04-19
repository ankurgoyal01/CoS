---
service: "AIGO-ContentServices"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values, dotenv-files]
---

# Configuration

## Overview

Each of the four components is configured via environment variables. Local development uses `.env` files (excluded from version control). Cloud deployments receive environment variables via Raptor/Kubernetes deployment manifests under `.meta/deployment/cloud/components/<component>/`. Per-environment overrides (staging, production) are defined in `staging-us-central1.yml` and `production-us-central1.yml` for each component.

## Environment Variables

### Content Generator Service (`continuumContentGeneratorService`)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `OPENAI_API_KEY` | OpenAI API key for LLM completions | yes | none | env / deployment manifest |
| `SF_INSTANCE_URL` | Salesforce instance base URL for bulk query API | yes | none | env / deployment manifest |
| `SF_USERNAME` | Salesforce authentication username | yes | none | env / `.env` file |
| `SF_PASSWORD` | Salesforce authentication password | yes | none | env / `.env` file |
| `SECRET_KEY` | Application secret key | yes | none | env / `.env` file |
| `PROMPT_DATABASE_URL` | Base URL for Prompt Database Service | yes | none | env / deployment manifest |

### Web Scraper Service (`continuumWebScraperService`)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `OPENAI_API_KEY` | OpenAI API key for scraper LLM agents | yes | none | env / deployment manifest |
| `PROMPT_DATABASE_URL` | Base URL of Prompt Database Service for agent configuration queries | yes | `http://aigo-contentservices--promptdb.staging.service` (hardcoded fallback in code) | env / deployment manifest |
| `SECRET_KEY` | Application secret key | yes | none | env / `.env` file |

### Prompt Database Service (`continuumPromptDatabaseService`)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `POSTGRES_USER` | PostgreSQL database username | yes | none | env / `.env` file |
| `POSTGRES_PASSWORD` | PostgreSQL database password | yes | none | env / `.env` file |
| `POSTGRES_DB` | PostgreSQL database name | yes | none | env / `.env` file |
| `DATABASE_URL` | Full SQLAlchemy connection string | yes | none | env / `.env` file |

### Frontend Content Generator (`continuumFrontendContentGenerator`)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NEXT_PUBLIC_APP_URL` | Public URL of the frontend application | yes | none | deployment manifest |
| `NEXT_PUBLIC_GENERATOR_URL` | Base URL for Content Generator Service API calls | yes | none | deployment manifest |
| `NEXT_PUBLIC_SCRAPER_URL` | Base URL for Web Scraper Service API calls | yes | none | deployment manifest |
| `NEXT_PUBLIC_PROMPTDB_URL` | Base URL for Prompt Database Service API calls | yes | none | deployment manifest |

> IMPORTANT: Secret values are never documented here. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in codebase. No feature flag system (LaunchDarkly, config-driven flags, etc.) is implemented.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `service_prompt_database/alembic.ini` | INI | Alembic database migration configuration (database connection string reference) |
| `service_prompt_database/data/pds_conversion.csv` | CSV | Static mapping from PDS codes to L2 category and TG taxonomy group values; bundled in container image |
| `service_prompt_database/alembic/data/ai_agents.json` | JSON | Seed data for `agent_configurations` table applied during initial migration |
| `service_prompt_database/alembic/data/l1_guidelines.json` | JSON | Seed data for `l1_guidelines` table |
| `service_prompt_database/alembic/data/l2_guidelines.json` | JSON | Seed data for `l2_guidelines` table |
| `service_prompt_database/alembic/data/tg_guidelines.json` | JSON | Seed data for `tg_guidelines` table |
| `.meta/deployment/cloud/components/*/common.yml` | YAML | Raptor component definitions (serviceId, appImage, port, scaling, probe config) |
| `.meta/deployment/cloud/components/*/staging-us-central1.yml` | YAML | Staging environment overrides (env vars, region, VPC, replicas) |
| `.meta/deployment/cloud/components/*/production-us-central1.yml` | YAML | Production environment overrides (env vars, region, VPC, replicas) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `OPENAI_API_KEY` | OpenAI API authentication | env (deployment manifest / Raptor secrets at `.meta/deployment/cloud/secrets`) |
| `SF_INSTANCE_URL` | Salesforce instance URL | env (deployment manifest) |
| `SF_USERNAME` | Salesforce login credential | env / Raptor secrets |
| `SF_PASSWORD` | Salesforce login credential | env / Raptor secrets |
| `POSTGRES_USER` | Database credential | env / Raptor secrets |
| `POSTGRES_PASSWORD` | Database credential | env / Raptor secrets |
| `SECRET_KEY` | Application signing key | env / Raptor secrets |

> Secret values are never documented. Secret path is `.meta/deployment/cloud/secrets` per `.meta/.raptor.yml`.

## Per-Environment Overrides

### Staging (`staging-us-central1`)
- `cloudProvider: gcp`, `deployEnv: staging`, `region: us-central1`, `vpc: stable`
- Frontend URLs point to `*.staging.service.us-central1.gcp.groupondev.com`
- Generator `SF_INSTANCE_URL`: `https://groupon-dev.my.salesforce.com`
- Generator `PROMPT_DATABASE_URL`: `http://aigo-contentservices--promptdb.staging.service`
- Scaling: `minReplicas: 1`, `maxReplicas: 2`

### Production (`production-us-central1`)
- `cloudProvider: gcp`, `deployEnv: production`, `region: us-central1`, `vpc: prod`
- Frontend URLs point to `*.production.service.us-central1.gcp.groupondev.com`
- Generator `SF_INSTANCE_URL`: `https://groupon-dev.my.salesforce.com`
- Generator `PROMPT_DATABASE_URL`: `http://aigo-contentservices--promptdb.production.service:7000`
- Scaling: `minReplicas: 1`, `maxReplicas: 2`
