---
service: "tdo-team"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources:
  - env-vars
  - helm-values
  - config-files
---

# Configuration

## Overview

Each cronjob is configured through a two-level YAML system: a `common.yml` file defines shared settings (image, resource requests, entrypoint, base env vars), and per-environment YAML files (e.g., `production-us-central1.yml`, `staging-us-central1.yml`) provide environment-specific overrides such as cron schedules and service URLs. Environment variables are injected by Kubernetes at pod startup via Helm-rendered manifests. Secrets (Jira API tokens, Google OAuth credentials, Pingdom API keys, OpsGenie keys) are embedded in the scripts for legacy reasons; the standard pattern is to migrate these to Kubernetes secrets or Vault.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `SP_URL` | Base URL for the Service Portal API | yes | `http://service-portal.production.service` | helm (per-env YAML) |
| `JTIER_RUN_CMD` | Dropwizard command selector (legacy jtier pattern) | yes | `cron` | helm (common.yml) |
| `JTIER_RUN_CONFIG` | Path to runtime configuration file | yes | `/var/groupon/jtier/config/cloud/production-us-west-1.yml` | helm (per-env YAML) |
| `TERM_FILE` | Path to termination signal file used by cronjob shell scripts | yes | `/tmp/signals/terminated` | helm (common.yml) |
| `PYTHONPATH` | Python module search path including ir-automation package | yes | `/tdo-team/cronjobs/ir-automation` | Dockerfile |

## Feature Flags

> No evidence found in codebase. No feature flags are defined.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/{component}/common.yml` | YAML | Shared Kubernetes CronJob configuration per component (image, resources, entrypoint, base env vars) |
| `.meta/deployment/cloud/components/{component}/production-us-central1.yml` | YAML | Production (GCP us-central1) schedule and environment overrides |
| `.meta/deployment/cloud/components/{component}/production-us-west-1.yml` | YAML | Production (AWS us-west-1) schedule and environment overrides |
| `.meta/deployment/cloud/components/{component}/staging-us-central1.yml` | YAML | Staging (GCP us-central1) schedule and environment overrides |
| `.meta/deployment/cloud/components/{component}/staging-us-west-1.yml` | YAML | Staging (GCP us-west-1) schedule and environment overrides |
| `cronjobs/ir-automation/settings.py` | Python | IR Automation constants: Google Drive IDs, Jira options, Service Portal URL, Slack webhook URL |
| `cronjobs/ir-automation/Pipfile` | TOML | Python dependency manifest for the ir-automation package |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Jira Basic Auth token | Authenticates calls to `https://groupondev.atlassian.net/rest/api/2/` | Embedded in scripts (legacy; should be k8s-secret) |
| Google OAuth credentials | OAuth 2.0 credentials for Google Drive/Docs API | `secrets/google_secrets.json` (mounted into container) |
| Pingdom API key and authorization key | Authenticates calls to `https://api.pingdom.com/api/2.1` | Embedded in `cronjobs/pingdom-shift-report.sh` (legacy) |
| OpsGenie API key | Authenticates calls to `https://api.opsgenie.com/v2/` | Embedded in `cronjobs/weekend-oncall.sh` and `cronjobs/sev4-reminders.sh` (legacy) |
| Google Chat webhook URLs | Webhook endpoints for posting to Google Chat spaces | Embedded in cronjob shell scripts |
| Slack webhook URL | Webhook endpoint for IR automation notifications | `settings.py` (`SLACK_WEBHOOK_URL`) |

> Secret values are NEVER documented here. Only names and purposes are listed.

## Per-Environment Overrides

Each cronjob component has separate YAML files per deployment target. Key differences between environments:

| Component | Staging Schedule | Production Schedule |
|-----------|-----------------|---------------------|
| `advisory-actions-reminders` | Defined per staging YAML | `0 7 1 * *` (monthly, 1st at 07:00 UTC) |
| `subtask-reminders` | Defined per staging YAML | `0 8 * * *` (daily at 08:00 UTC) |
| `close-logbooks` | Defined per staging YAML | `0 8 * * *` (daily at 08:00 UTC) |
| `sev4-reminders` | Defined per staging YAML | `0 9 * * 1` (Mondays at 09:00 UTC) |
| `weekend-oncall` | Defined per staging YAML | `0 2,10,17 * * 3,5` (Wed and Fri at 02:00, 10:00, 17:00 UTC) |
| `pingdom-shift-report` | Defined per staging YAML | `0 0,4,8,12,16,20 * * *` (every 4 hours) |
| `imoc-ooo-weekend` | Defined per staging YAML | `0 */4 * * 6,0` (every 4 hours on Saturday and Sunday) |
| `ir-automation` | Defined per staging YAML | `*/30 * * * *` (every 30 minutes) |

The `SP_URL` variable is set to `http://service-portal.production.service` in production environments. Staging environments use their own service portal URL. The `ir-automation` component does not use `SP_URL` (service portal calls are made directly from `settings.py` constants).
