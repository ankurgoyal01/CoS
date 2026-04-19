---
service: "pingdom"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["service-yml"]
---

# Configuration

## Overview

The Pingdom service registry entry is configured entirely through the `.service.yml` metadata file. There is no application runtime, so there are no environment variables, feature flags, or config files beyond the service definition itself. Configuration for consuming integrations (Pingdom API credentials, uptime thresholds) lives in those consuming services.

## Environment Variables

> No evidence found in codebase for the Pingdom service portal itself.

The following environment variables are used by the **consuming** `tdo-team` pingdom-shift-report cron job (documented here for operational context):

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `TERM_FILE` | Path to termination signal file used by Kubernetes readiness/liveness probes | yes | `/tmp/signals/terminated` | env (Kubernetes) |
| `JTIER_RUN_CMD` | Dropwizard run command override for the cron container | yes | `cron` | env (Helm/Kubernetes) |

The following Django settings are used by **`ein_project`** for Pingdom data collection:

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `UPTIME_ALERT_THRESHOLD` | Uptime percentage below which a JSM alert is created | no | `99.0` | env / Django settings |
| `IMOC_TEAM` | JSM team ID for the IMOC responder team | yes | none | env / Django settings |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.service.yml` | YAML | Service metadata: name, owner, SRE contacts, PagerDuty link, Slack channel, Confluence docs, status endpoint and schema flags |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Pingdom API key | Authenticates calls to `https://api.pingdom.com/api/2.1` (header: `App-Key`) | Managed by consuming services; not stored in this repository |
| Pingdom Authorization Key | Base64-encoded Basic Auth credentials for Pingdom API access | Managed by consuming services; not stored in this repository |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase. The Pingdom service registry entry has no per-environment configuration. The `.service.yml` `branch` field lists `master` as the single tracked branch, indicating no environment-specific overrides at the metadata level.
