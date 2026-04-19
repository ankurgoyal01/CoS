---
service: "dmarc"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, secrets-volume]
---

# Configuration

## Overview

The DMARC service is configured through two mechanisms: a TOML file (`config.toml`) baked into the container image for all non-secret parameters, and a secrets volume mounted at runtime that provides the Gmail OAuth2 credentials and token files. A single environment variable (`DEPLOY_ENV`) switches the service between staging (one-shot) and production (continuous polling) execution modes. No consul, vault, or Helm-values-based runtime configuration is used beyond what the deployment tooling injects.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DEPLOY_ENV` | Controls execution mode: `staging` runs a single-message fetch and exits; any other value (including unset) runs the continuous 1-minute polling loop | No | `""` (production mode) | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. No feature flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.toml` | TOML | Primary application configuration: Gmail path, credentials/token file paths, log file path, worker count, Gmail user, and Gmail search query. Loaded at startup via `pelletier/go-toml/v2`. |

### `config.toml` Reference

```toml
[gmail]
path = "/app"                            # Root path for relative file resolution
credentials = "credentials/credentials.json"  # Path to Gmail OAuth2 client credentials (relative to path)
token = "token/token.json"               # Path to Gmail OAuth2 refresh token (relative to path)
applogger = "logs/dmarc_log.log"         # Output log file for parsed DMARC JSON records
workers = 3                              # Number of concurrent report-processing goroutines
user = "me"                              # Gmail API user identifier
query = "label: rua is:unread"           # Gmail search query for selecting DMARC report emails
```

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `credentials/credentials.json` | Gmail OAuth2 client ID and client secret for authenticating to the Google Gmail API | Secrets volume (mounted from internal secrets repository at container path `/app/credentials/`) |
| `token/token.json` | Gmail OAuth2 access token and refresh token for the `svc_dmarc@groupon.com` account | Secrets volume (mounted from internal secrets repository at container path `/app/token/`) |

> Secret values are NEVER documented. Only names and locations are shown. See `.meta/.raptor.yml` (`secret_path: ".meta/deployment/cloud/secrets"`) for the secrets path convention.

## Per-Environment Overrides

- **Staging** (`DEPLOY_ENV=staging`): Processes exactly one Gmail message then blocks (keeps the heartbeat HTTP server alive for Kubernetes). Uses the same `config.toml`; no separate TOML file per environment.
- **Production** (default): Runs the 1-minute polling loop indefinitely. Gmail query selects all unread messages with the `rua` label; pagination fetches up to 500 messages per page.
- **Scaling config** differs per environment via Helm values overlaid by the deploy script:
  - Staging: `minReplicas: 1`, `maxReplicas: 1`
  - Production: `minReplicas: 2`, `maxReplicas: 15`
- **Filebeat log config** is set in `common.yml`: `sourceType: mta_dmarc`, log directory `/app/logs/`, file `dmarc_log.log`, JSON format.
