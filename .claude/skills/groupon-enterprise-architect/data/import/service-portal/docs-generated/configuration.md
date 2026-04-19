---
service: "service-portal"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Service Portal is configured primarily through environment variables injected at runtime by Kubernetes. Database and Redis connection strings, external API credentials, and application-level settings are all supplied via environment variables. Rails environment-specific config files (`config/environments/`) provide secondary configuration for framework behavior. No external config store (Consul, Vault) is evidenced in the inventory; secrets are managed as Kubernetes secrets injected as env vars.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for `continuumServicePortalDb` | yes | none | env / k8s-secret |
| `REDIS_URL` | Redis connection string for `continuumServicePortalRedis` (Sidekiq queue and cache) | yes | none | env / k8s-secret |
| `GITHUB_WEBHOOK_SECRET` | HMAC secret for verifying inbound GitHub webhook payloads (`X-Hub-Signature-256`) | yes | none | env / k8s-secret |
| `GITHUB_API_TOKEN` | Personal access token or app token for outbound GitHub Enterprise REST API calls | yes | none | env / k8s-secret |
| `GITHUB_API_BASE_URL` | Base URL for GitHub Enterprise REST API | yes | none | env |
| `GOOGLE_SERVICE_ACCOUNT_CREDENTIALS` | JSON credentials for Google service account (Chat and Directory APIs) | yes | none | env / k8s-secret |
| `GOOGLE_CHAT_SPACE_ID` | Google Chat space ID for governance alert notifications | yes | none | env |
| `GOOGLE_DIRECTORY_DOMAIN` | Google Workspace domain for Directory API group lookups | yes | none | env |
| `JIRA_BASE_URL` | Jira Cloud base URL for ORR issue creation | no | none | env |
| `JIRA_API_TOKEN` | Jira Cloud API token | no | none | env / k8s-secret |
| `JIRA_USER_EMAIL` | Email address for Jira API authentication | no | none | env |
| `RAILS_ENV` | Rails environment (`production`, `staging`, `development`, `test`) | yes | `development` | env |
| `RAILS_MASTER_KEY` | Rails credentials master key for decrypting `config/credentials.yml.enc` | yes | none | env / k8s-secret |
| `SECRET_KEY_BASE` | Rails session secret key | yes | none | env / k8s-secret |
| `PORT` | HTTP port for Puma to bind | no | `3000` | env |
| `WEB_CONCURRENCY` | Number of Puma worker processes | no | `2` | env |
| `RAILS_MAX_THREADS` | Puma threads per worker | no | `5` | env |
| `SIDEKIQ_CONCURRENCY` | Number of Sidekiq threads | no | Sidekiq default | env |
| `ELASTIC_APM_SERVER_URL` | Elastic APM server endpoint for distributed tracing | no | none | env |
| `ELASTIC_APM_SECRET_TOKEN` | Elastic APM authentication token | no | none | env / k8s-secret |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

> No evidence found for a feature flag system. Feature gating is not in evidence in the service inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | YAML | ActiveRecord database connection configuration (reads `DATABASE_URL`) |
| `config/sidekiq.yml` | YAML | Sidekiq queue definitions, concurrency, and cron schedule entries |
| `config/environments/production.rb` | Ruby | Rails production environment configuration (logging, caching, asset pipeline) |
| `config/environments/staging.rb` | Ruby | Rails staging environment overrides |
| `config/environments/development.rb` | Ruby | Rails development environment configuration |
| `config/credentials.yml.enc` | Encrypted YAML | Encrypted secrets accessed via `RAILS_MASTER_KEY` |
| `Dockerfile` | Dockerfile | Container image definition (Alpine 3.22 base) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GITHUB_WEBHOOK_SECRET` | HMAC verification of inbound GitHub webhooks | k8s-secret |
| `GITHUB_API_TOKEN` | Authentication for outbound GitHub Enterprise REST calls | k8s-secret |
| `GOOGLE_SERVICE_ACCOUNT_CREDENTIALS` | Google API authentication (Chat + Directory) | k8s-secret |
| `JIRA_API_TOKEN` | Jira Cloud API authentication | k8s-secret |
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` | k8s-secret |
| `SECRET_KEY_BASE` | Rails session signing | k8s-secret |
| `DATABASE_URL` | MySQL credentials embedded in connection string | k8s-secret |
| `REDIS_URL` | Redis credentials embedded in connection string | k8s-secret |
| `ELASTIC_APM_SECRET_TOKEN` | Elastic APM agent authentication | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

- **production**: Full Puma multi-process configuration; all external integrations active; Elastic APM enabled; log level `info`; asset serving disabled (CDN / reverse proxy assumed)
- **staging**: Same external integrations as production with staging-specific credentials; reduced replica count; Elastic APM may be enabled
- **development**: SQLite or local MySQL; local Redis; GitHub integration disabled or pointed at test fixtures; Google API calls may be stubbed; log level `debug`
- **test**: In-memory or test database; all external API calls stubbed; Sidekiq runs inline (synchronous) via `sidekiq/testing`
