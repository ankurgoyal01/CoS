---
service: "ckod-worker"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

CKOD Worker is a Python service configured through environment variables. No external config store (Consul, Vault, Helm values) is referenced in the architecture model. Configuration covers database connections, SaaS API credentials, Google Cloud service account access, and webhook URLs.

## Environment Variables

> No evidence found in codebase for specific environment variable names. The following are inferred from the integration landscape documented in the architecture model.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `CKOD_DATABASE_URL` | MySQL connection string for `continuumCkodMySql` | yes | none | env |
| `SERVICE_PORTAL_DATABASE_URL` | MySQL connection string for `servicePortal` | yes | none | env |
| `OPTIMUS_PRIME_DATABASE_URL` | PostgreSQL connection string for `optimusPrime` | yes | none | env |
| `JIRA_BASE_URL` | Base URL for Jira Cloud REST API | yes | none | env |
| `JIRA_API_TOKEN` | API token for Jira Cloud authentication | yes | none | env |
| `JIRA_USER_EMAIL` | Email address associated with Jira API token | yes | none | env |
| `JSM_OPS_API_TOKEN` | API token for JSM Ops API | yes | none | env |
| `KEBOOLA_API_TOKEN` | API token for Keboola Storage and Queue APIs | yes | none | env |
| `KEBOOLA_BASE_URL` | Base URL for Keboola API endpoints | yes | none | env |
| `GOOGLE_CHAT_WEBHOOK_URL` | Google Chat incoming webhook URL for operational notifications | yes | none | env |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to Google Cloud service account JSON for Vertex AI | yes | none | env |
| `VERTEX_AI_PROJECT` | Google Cloud project ID for Vertex AI reasoning engine | yes | none | env |
| `VERTEX_AI_LOCATION` | Google Cloud region for Vertex AI reasoning engine | yes | none | env |
| `CKOD_UI_BASE_URL` | Base URL for CKOD UI API (agent task polling) | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in codebase for feature flag system or specific flags.

## Config Files

> No evidence found in codebase for specific named configuration files beyond standard Python conventions.

| File | Format | Purpose |
|------|--------|---------|
| `config/scheduler.yml` | yaml | APScheduler job definitions and intervals (inferred; verify against codebase) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `JIRA_API_TOKEN` | Jira Cloud API authentication | env |
| `JSM_OPS_API_TOKEN` | JSM Ops API authentication | env |
| `KEBOOLA_API_TOKEN` | Keboola API authentication | env |
| `GOOGLE_APPLICATION_CREDENTIALS` | Google Cloud service account for Vertex AI | env |
| `GOOGLE_CHAT_WEBHOOK_URL` | Google Chat webhook (contains embedded auth token) | env |
| `CKOD_DATABASE_URL` | CKOD MySQL connection (includes password) | env |
| `SERVICE_PORTAL_DATABASE_URL` | Service Portal MySQL connection (includes password) | env |
| `OPTIMUS_PRIME_DATABASE_URL` | Optimus Prime PostgreSQL connection (includes password) | env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase for specific per-environment configuration differences. Standard Python environment conventions apply (development, staging, production environment variable sets).
