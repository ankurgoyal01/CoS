---
service: "mobilebot"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets, helm-values]
---

# Configuration

## Overview

Mobilebot is configured via environment variables injected at container runtime by Kubernetes (Helm chart via `cmf-java-api` chart template). Per-environment values are defined in `.meta/deployment/cloud/components/mobilebot/{env}.yml` and merged with `common.yml` at deploy time. Secrets are stored in `.meta/deployment/cloud/secrets/` and are never committed in plain text. A `CONFIG_FILE` path is injected pointing to a mounted cloud config YAML file.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `REDIS_URL` | Redis connection URL for conversation state store | yes | localhost (macOS dev) | helm/k8s secret |
| `GITHUB_API_TOKEN` | GitHub Enterprise API token for reading release branch refs | yes | — | k8s secret |
| `GITHUB_BASE_URL` | Base hostname for GitHub Enterprise API (e.g., `github.production.service`) | yes | — | env (deployment yml) |
| `PAGERDUTY_TOKEN` | PagerDuty API token for on-call schedule queries | yes | — | k8s secret |
| `ATLASSIAN_API_TOKEN` | Atlassian API token for Jira issue creation and user lookups | yes | — | k8s secret |
| `ATLASSIAN_API_EMAIL` | Atlassian account email for Jira API basic auth | yes | — | k8s secret |
| `JIRA_BASE_URL` | Internal DNS base URL for Jira REST API (e.g., `jira.production.service`) | yes | — | env (deployment yml) |
| `CI_BASE_URL` | Internal DNS base URL for Jenkins CI (e.g., `ci.production.service`) | yes | — | env (deployment yml) |
| `ITC_USERNAME` | Apple Developer account username for App Store Connect queries | yes | — | k8s secret |
| `ITC_PASSWORD` | Apple Developer account password for App Store Connect queries | yes | — | k8s secret |
| `ITC_BRAND` | App Store brand selector (`groupon` or `livingsocial`) | no | `groupon` | runtime (set by command handler) |
| `CONFIG_FILE` | Path to mounted cloud environment config YAML | yes | — | env (deployment yml) |
| `USE_FILE_LOG` | If `true`, logs to file (`/app/log/steno.log`); otherwise logs to console | no | `false` | env (deployment yml) |
| `IS_PRODUCTION` | Marks the running environment as production | no | `false` | env (deployment yml) |
| `DOCKER_ONPREM` | Flags on-premises Docker deployment (legacy) | no | `false` | env (deployment yml) |
| `HUBOT_GITHUB_API_URL` | GitHub API base URL override for Hubot internals | no | `https://github.groupondev.com/api/v3` | `.env` file |
| `TESTRAIL_TOKEN` | TestRail API token for fetching verification milestone URLs in GPROD creation | no | — | k8s secret |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No feature flag system is configured. Room-based access control (ACL) is the only runtime permission gate; allowed room IDs are hardcoded in `scripts/helpers/validate_room_permission.js`.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/mobilebot/common.yml` | YAML | Common Kubernetes deployment config (image, replicas, ports, resource limits, log config) |
| `.meta/deployment/cloud/components/mobilebot/{env}.yml` | YAML | Per-environment overrides (cloud provider, region, VIP, env vars, telegraf URL) |
| `.meta/deployment/cloud/secrets/{env}.yml` | YAML (encrypted) | Per-environment secret values (not committed in plain text) |
| `.meta/deployment/cloud/secrets/ci-groupon-playstore.json` | JSON | Google service account key for Play Store API access |
| `.env` | dotenv | Local development overrides (only `HUBOT_GITHUB_API_URL` currently set) |
| `scripts/ruby/.env.local` / `scripts/ruby/.env` | dotenv | Ruby script local environment overrides for Apple credentials |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `REDIS_URL` | Redis connection string including host and auth | k8s-secret |
| `GITHUB_API_TOKEN` | GitHub Enterprise personal access token | k8s-secret |
| `PAGERDUTY_TOKEN` | PagerDuty REST API token | k8s-secret |
| `ATLASSIAN_API_TOKEN` | Atlassian API token | k8s-secret |
| `ATLASSIAN_API_EMAIL` | Atlassian account email | k8s-secret |
| `ITC_USERNAME` | Apple Developer account username | k8s-secret |
| `ITC_PASSWORD` | Apple Developer account password | k8s-secret |
| `TESTRAIL_TOKEN` | TestRail API token | k8s-secret |
| `ci-groupon-playstore.json` | Google Play service account key | k8s-secret (mounted as file) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Variable | dev | staging | production |
|----------|-----|---------|-----------|
| `IS_PRODUCTION` | `false` | `false` | `true` |
| `JIRA_BASE_URL` | `jira--production.staging.service` | `jira--production.staging.service` | `jira.production.service` |
| `CI_BASE_URL` | `ci.staging.service` | `ci.staging.service` | `ci.production.service` |
| `GITHUB_BASE_URL` | `github--production.staging.service` | `github--production.staging.service` | `github.production.service` |
| `CONFIG_FILE` | `/var/groupon/config/cloud/dev-us-west-1.yml` | `/var/groupon/config/cloud/staging-us-west-1.yml` | `/var/groupon/config/cloud/production-us-west-1.yml` |

All environments set `USE_FILE_LOG: true` and `DOCKER_ONPREM: false` in cloud deployments.
