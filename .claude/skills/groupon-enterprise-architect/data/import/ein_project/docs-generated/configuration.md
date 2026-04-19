---
service: "ein_project"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

ProdCat is configured via environment variables injected at runtime. Database and Redis connection strings, external API credentials, and Django secrets are all supplied through environment variables — no config files committed to source are used for sensitive values. The Django `settings.py` module reads these variables at startup. Deployment-specific overrides (dev vs. staging vs. production) are applied by varying the environment variable values supplied by the orchestration layer.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for `continuumProdcatPostgres` (Cloud SQL) | yes | None | env |
| `REDIS_URL` | Redis connection string for `continuumProdcatRedis` (Memorystore) | yes | None | env |
| `SECRET_KEY` | Django secret key for session signing and CSRF protection | yes | None | env / k8s-secret |
| `JIRA_BASE_URL` | Base URL for JIRA Cloud API v3 | yes | None | env |
| `JIRA_API_EMAIL` | Email identity for JIRA API authentication | yes | None | env / k8s-secret |
| `JIRA_API_TOKEN` | JIRA Cloud API token | yes | None | env / k8s-secret |
| `JSM_API_TOKEN` | Jira Service Management API token for incident queries | yes | None | env / k8s-secret |
| `PAGERDUTY_API_TOKEN` | PagerDuty REST API token for incident monitoring | yes | None | env / k8s-secret |
| `GOOGLE_CHAT_WEBHOOK_URL` | Google Chat webhook URL for deployment notifications | yes | None | env / k8s-secret |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to Google service account credentials JSON | no | None | env |
| `WAVEFRONT_API_TOKEN` | Wavefront API token for metrics emission | no | None | env / k8s-secret |
| `WAVEFRONT_SERVER` | Wavefront server URL | no | None | env |
| `GITHUB_API_TOKEN` | GitHub API token for deployment metadata retrieval | no | None | env / k8s-secret |
| `SERVICE_PORTAL_BASE_URL` | Base URL for the internal Service Portal API | yes | None | env |
| `SERVICE_PORTAL_API_TOKEN` | Auth token for Service Portal calls | yes | None | env / k8s-secret |
| `ALLOWED_HOSTS` | Django ALLOWED_HOSTS setting | yes | None | env |
| `DEBUG` | Django debug mode (must be False in production) | yes | False | env |
| `RQ_QUEUES` | RQ queue configuration (Redis URL and queue names) | yes | None | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found of a dedicated feature flag system. Behavioral configuration is controlled via the `/api/settings/` endpoint backed by the database settings table.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `settings.py` | Python | Django application settings; reads all configuration from environment variables |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `JIRA_API_TOKEN` | Authenticates JIRA Cloud API calls | k8s-secret / env |
| `JSM_API_TOKEN` | Authenticates JSM incident queries | k8s-secret / env |
| `PAGERDUTY_API_TOKEN` | Authenticates PagerDuty incident queries | k8s-secret / env |
| `GOOGLE_CHAT_WEBHOOK_URL` | Authorized Google Chat webhook | k8s-secret / env |
| `WAVEFRONT_API_TOKEN` | Authenticates Wavefront metrics emission | k8s-secret / env |
| `GITHUB_API_TOKEN` | Authenticates GitHub metadata queries | k8s-secret / env |
| `SERVICE_PORTAL_API_TOKEN` | Authenticates Service Portal calls | k8s-secret / env |
| `SECRET_KEY` | Django session and CSRF signing | k8s-secret / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `DEBUG=True`; local PostgreSQL and Redis instances; placeholder API tokens for external services; `ALLOWED_HOSTS=localhost`.
- **Staging**: `DEBUG=False`; Cloud SQL and Memorystore instances in a non-production GCP project; staging JIRA project; test PagerDuty account.
- **Production**: `DEBUG=False`; production Cloud SQL and Memorystore; live JIRA Cloud, JSM, PagerDuty, Google Chat, Service Portal, and Wavefront credentials; `ALLOWED_HOSTS` scoped to the production domain.
