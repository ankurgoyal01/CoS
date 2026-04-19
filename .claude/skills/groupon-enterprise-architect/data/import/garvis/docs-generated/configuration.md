---
service: "garvis"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, django-settings]
---

# Configuration

## Overview

Garvis is configured primarily through environment variables injected at runtime. Django settings consume these variables to configure the database connection, Redis connection, Google API credentials, JIRA, PagerDuty, GitHub, and other integration secrets. No external config store (Consul, Vault, Helm values) is evidenced in the architecture model; secrets are expected to be injected via environment at deployment time.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for `continuumJarvisPostgres` | yes | None | env |
| `REDIS_URL` | Redis connection string for `continuumJarvisRedis` (RQ and cache) | yes | None | env |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to Google service account key file for Pub/Sub, Chat, Drive, Docs, Calendar APIs | yes | None | env |
| `GOOGLE_CHAT_PROJECT_ID` | Google Cloud project ID for Pub/Sub subscription | yes | None | env |
| `GOOGLE_CHAT_SUBSCRIPTION_NAME` | Pub/Sub subscription name for Google Chat events | yes | None | env |
| `JIRA_SERVER` | Base URL for the Groupon JIRA instance | yes | None | env |
| `JIRA_USERNAME` | JIRA API username or email | yes | None | env |
| `JIRA_API_TOKEN` | JIRA API token for authentication | yes | None | env |
| `PAGERDUTY_API_KEY` | PagerDuty REST API key for on-call and incident operations | yes | None | env |
| `GITHUB_TOKEN` | GitHub personal access token or App token for repository queries | yes | None | env |
| `SECRET_KEY` | Django secret key for cryptographic signing | yes | None | env |
| `DEBUG` | Django debug mode flag | no | `False` | env |
| `ALLOWED_HOSTS` | Django allowed hosts for HTTP request validation | yes | None | env |
| `PRODCAT_API_URL` | Base URL for the internal ProdCAT service | no | None | env |
| `SERVICE_HEALTH_API_URL` | Base URL for the internal Service Health / ORR service | no | None | env |

> IMPORTANT: Secret values are never documented here. Only variable names and purposes are recorded.

## Feature Flags

> No evidence found of application-level feature flags in the architecture model.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| Django settings module | Python | Central configuration module; reads environment variables and configures all Django, database, cache, RQ, and integration settings |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `JIRA_API_TOKEN` | Authenticates outbound JIRA REST API calls | env (injected at deploy) |
| `PAGERDUTY_API_KEY` | Authenticates PagerDuty REST API calls | env (injected at deploy) |
| `GITHUB_TOKEN` | Authenticates GitHub API calls | env (injected at deploy) |
| `GOOGLE_APPLICATION_CREDENTIALS` | Google service account key for all Google API integrations | env (injected at deploy) |
| `SECRET_KEY` | Django secret key for session signing and CSRF | env (injected at deploy) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- `DEBUG=False` is expected in all production and staging environments; `DEBUG=True` only in local development
- `DATABASE_URL` and `REDIS_URL` point to environment-specific instances of `continuumJarvisPostgres` and `continuumJarvisRedis`
- `ALLOWED_HOSTS` is scoped to the environment-specific hostname(s)
- Google Pub/Sub subscription names and project IDs differ per environment to isolate message streams
