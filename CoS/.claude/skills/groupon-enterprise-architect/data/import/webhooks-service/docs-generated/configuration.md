---
service: "webhooks-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, vault]
---

# Configuration

## Overview

The service is configured primarily through environment variables injected at deployment time by the Conveyor/Kubernetes deployment system. Non-secret values are specified directly in per-environment YAML manifests under `.meta/deployment/cloud/components/webhooks-service/`. Secret values (API tokens) are loaded from a secrets file at `.meta/deployment/cloud/secrets/` (excluded from source control). In local development, secrets are sourced from an on-prem `.env` file loaded via `dotenv`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GITHUB_SERVICE_URL` | Base URL for the GitHub Enterprise instance used for all API calls | yes | None | env manifest (per-environment) |
| `GITHUB_API_TOKEN` | Bearer token authenticating the `svc-github-webhook` bot user against GitHub Enterprise API | yes | None | vault / secrets file |
| `GITHUB_USER` | GitHub username of the bot account (`svc-github-webhook`) used to identify comments the service has authored | yes | None | vault / secrets file |
| `JIRA_SERVICE_URL` | Base URL for the Jira Cloud API (e.g., `https://groupondev.atlassian.net`) | yes | None | env manifest (per-environment) |
| `JIRA_API_TOKEN` | Base64-encoded Basic Auth credential for Jira REST API v2 | yes | None | vault / secrets file |
| `SLACK_API_TOKEN` | Slack Web API bot token for sending messages | yes | None | vault / secrets file |
| `CI_SERVICE_URL` | Internal URL for the DotCI Jenkins instance (bypasses Okta) | yes | None | env manifest (per-environment) |
| `CJ_SERVICE_URL` | Internal URL for the Cloud Jenkins instance (bypasses Okta) | yes | None | env manifest (per-environment) |
| `CONFIG_FILE` | Path to the per-environment YAML config file mounted into the container | yes | None | env manifest (per-environment) |
| `NODE_TLS_REJECT_UNAUTHORIZED` | Disables TLS certificate validation (set to `0` in all cloud environments) | yes | `1` (Node default) | env manifest (per-environment) |
| `USE_FILE_LOG` | Enables file-based logging to `/app/log/steno.log` when set to `"true"` | no | Not set | env manifest (per-environment) |
| `DOCKER_ONPREM` | When set, triggers loading of on-prem secrets from `export_secrets.sh` at container startup | no | Not set | Container entrypoint logic |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. The service does not implement a feature flag system. Hook enable/disable is controlled by `enabled: true/false` in per-repository `.webhooks.yml` files, not by service-level flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/webhooks-service/common.yml` | YAML | Shared Kubernetes deployment config: image name, replica bounds, log config, port mappings, health check probes |
| `.meta/deployment/cloud/components/webhooks-service/production-us-central1.yml` | YAML | Production GCP us-central1 overrides: VIP, replica counts, resource requests, non-secret env vars |
| `.meta/deployment/cloud/components/webhooks-service/production-us-west-1.yml` | YAML | Production AWS us-west-1 overrides: VIP, replica counts, resource requests, non-secret env vars |
| `.meta/deployment/cloud/components/webhooks-service/production-us-west-2.yml` | YAML | Production AWS us-west-2 overrides: VIP, replica counts, resource requests, non-secret env vars |
| `.meta/deployment/cloud/components/webhooks-service/staging-us-central1.yml` | YAML | Staging GCP us-central1 overrides: VIP, replica counts, reduced resource requests |
| `.meta/deployment/cloud/components/webhooks-service/staging-us-west-1.yml` | YAML | Staging AWS us-west-1 overrides |
| `.meta/deployment/cloud/components/webhooks-service/staging-us-west-2.yml` | YAML | Staging AWS us-west-2 overrides |
| `.meta/deployment/cloud/components/webhooks-service/dev-us-central1.yml` | YAML | Dev environment overrides: reduced CPU/memory limits, Kafka filebeat endpoint for staging log pipeline |
| `.webhooks.yml` | YAML | Per-repository user-configurable hook definitions. This file lives in each consumer repository, not in the service itself. Read at request time from GitHub. |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GITHUB_API_TOKEN` | GitHub Enterprise API token for `svc-github-webhook` bot | vault / `.meta/deployment/cloud/secrets/` |
| `GITHUB_USER` | GitHub bot username | vault / `.meta/deployment/cloud/secrets/` |
| `JIRA_API_TOKEN` | Jira Basic Auth token (base64) | vault / `.meta/deployment/cloud/secrets/` |
| `SLACK_API_TOKEN` | Slack bot OAuth token | vault / `.meta/deployment/cloud/secrets/` |

> Secret values are NEVER documented. Only names and rotation policies are recorded here.

## Per-Environment Overrides

| Setting | dev | staging | production |
|---------|-----|---------|------------|
| `GITHUB_SERVICE_URL` | `https://github--production.staging.service` | `https://github--production.staging.service` | `https://github.production.service` |
| `JIRA_SERVICE_URL` | `https://groupondev.atlassian.net` | `https://groupondev.atlassian.net` | `https://groupondev.atlassian.net` |
| `CI_SERVICE_URL` | `http://ci--production.staging.service` | `http://ci--production.staging.service` | `http://ci.production.service` |
| CPU request | 50m (main), 10m (filebeat) | 50m | 100m |
| Memory request | 300Mi | 300Mi | 500Mi |
| Memory limit | 1Gi | 2Gi | 2Gi |
| Min replicas | 1 | 1 | 2–3 (region-dependent) |
| Max replicas | 1 | 1 | 3 |
