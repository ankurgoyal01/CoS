---
service: "groupon-monorepo"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [encore-secrets, env-vars, config-files, encore-config]
---

# Configuration

## Overview

The Encore Platform uses a multi-layered configuration approach. Secrets and sensitive credentials are managed through Encore's built-in secrets manager (`encore secret set`), which provides environment-specific secret injection at runtime. Non-sensitive service configuration uses Encore's typed config system (`config.Load[*ConfigType]()`) with CUE-based config files. Frontend applications use `.env` files for build-time environment variables. The Go backend uses Encore config and secrets following the same pattern. Python microservices use environment variables injected via Docker Compose.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment identifier | no | development | env |
| `USE_LOCAL_PYTHON` | Route Python AI calls to local Docker services | no | false | env |
| `TEMPORAL_WORKERS_ENABLED` | Enable Temporal workflow workers | no | 0 | env |
| `PORT` | Frontend server port (AIDG) | no | 3000 (dev) / 8080 (prod) | env |
| `CI` | CI environment flag (skips git hooks) | no | -- | env |
| `ENCORE_ENVIRONMENT` | Current Encore deployment environment | no | -- | encore |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Feature flags managed via `_core_system/feature-flags` service | Dynamic feature toggling for all services | per-flag | global |

The platform includes a dedicated feature-flags service that provides runtime feature flag management. Flags are queried by services at request time.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `biome.json` | JSON | Linter/formatter configuration (Biome 2.3.2) |
| `turbo.json` | JSON | Turborepo task pipeline configuration |
| `pnpm-workspace.yaml` | YAML | pnpm workspace package definitions |
| `apps/encore-ts/tsconfig.json` | JSON | TypeScript compiler configuration |
| `apps/admin-react-fe/next.config.ts` | TypeScript | Next.js frontend build configuration |
| `apps/admin-react-fe/.env` | dotenv | Frontend environment variables (from .env.example) |
| `apps/encore-go/*/config.cue` | CUE | Go service configuration per environment |
| `apps/microservices-python/docker-compose.dev.yml` | YAML | Python services local development configuration |
| `apps/microservices-python/nginx.conf` | Nginx | Python services reverse proxy configuration |
| `apps/microservices-python/supervisord.conf` | INI | Python services process management |
| `apps/microservices-python/fastapi-services.config.json` | JSON | FastAPI service registry and routing |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `OPENAI_API_KEY` | OpenAI LLM API access | Encore Secrets |
| `ANTHROPIC_API_KEY` | Anthropic Claude API access | Encore Secrets |
| `LANGSMITH_API_KEY` | LangSmith tracing API access | Encore Secrets |
| `LANGFUSE_CONNECTION_B2B_TRIBE` | Langfuse observability (B2B tribe project) | Encore Secrets |
| `LANGFUSE_CONNECTION_AI_TRIBE` | Langfuse observability (AI tribe project) | Encore Secrets |
| `LANGFUSE_CONNECTION_TEST_PROJECT` | Langfuse observability (test project) | Encore Secrets |
| `API_TOKEN_HMAC_SECRET` | HMAC key for API token signing | Encore Secrets |
| `REDIS_COMMON_ENCORE` | Redis connection URL | Encore Secrets |
| `GCP_AUTOMATION_CREDENTIAL_FEEDER_KEY` | GCP service account private key | Encore Secrets |
| `GCP_AUTOMATION_CREDENTIAL_FEEDER_EMAIL` | GCP service account email | Encore Secrets |
| `GCP_AUTOMATION_CREDENTIAL_FEEDER_PROJECT` | GCP project ID | Encore Secrets |
| `user_jwt_secret` | JWT signing secret for user tokens | Encore Secrets |
| `OAUTH_GOOGLE_CLIENT_SECRET` | Google OAuth client secret | Encore Secrets |
| `OAUTH_GOOGLE_CLIENT_ID` | Google OAuth client ID | Encore Secrets |
| `PUBLIC_FRONTEND_URL` | Public URL for frontend (OAuth redirect) | Encore Secrets |
| `DIGITAL_OCEAN_API_KEY` | DigitalOcean API access for Python service deployment | Encore Secrets |
| `GITHUB_E2E_QA_TOKEN` | GitHub API token for CI/deployment | Encore Secrets |
| `ENCORE_SERVICE_ACCOUNT_KEY` | Encore platform service account for audit log | Encore Secrets |
| `ATLASSIAN_API_TOKEN` | Atlassian Jira/Confluence API access | Encore Secrets |
| `ATLASSIAN_EMAIL` | Atlassian account email | Encore Secrets |

> Secret values are NEVER documented. Only names and rotation policies. Secrets are managed via `encore secret set <name>` and are environment-specific (development, staging, production).

## Per-Environment Overrides

The platform runs across multiple Encore Cloud environments:

- **Local development**: Services run locally via `encore run`. Secrets are loaded from the local Encore environment. Frontend uses `.env` file. Python services run in Docker Compose.
- **Staging**: Full deployment to Encore Cloud. Secrets are set for the staging environment. Frontend deployed to Cloud Run. Python services deployed to DigitalOcean droplet.
- **Production**: Full deployment to Encore Cloud. Production secrets with restricted access. Frontend deployed to Cloud Run with CDN. Python services deployed to DigitalOcean droplet (separate from staging).

Go backend services use `config.cue` files for per-environment configuration (e.g., Booster API endpoints, Vespa connection params, Redis TTL). TypeScript services rely primarily on Encore secrets for environment differentiation.
