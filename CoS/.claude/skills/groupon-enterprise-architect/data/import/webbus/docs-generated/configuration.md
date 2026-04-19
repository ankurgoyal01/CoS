---
service: "webbus"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Webbus is configured through a combination of static YAML configuration files (committed to the repository) and environment variables for secrets and environment identity. The active environment is resolved from the `ENV` or `RACK_ENV` environment variable at startup. All config files are in `config/` and are loaded by the `Common` module at boot time.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENV` | Sets the active environment (`development`, `staging`, `production`) | yes | `development` | env |
| `RACK_ENV` | Alternate environment identifier (fallback to `ENV`) | no | `development` | env |
| `WEBBUS_MESSAGEBUS_USER` | Message Bus STOMP authentication username | yes (staging/prod) | `guest` (dev only) | k8s-secret |
| `WEBBUS_MESSAGEBUS_PASSWORD` | Message Bus STOMP authentication password | yes (staging/prod) | `guest` (dev only) | k8s-secret |
| `RAILS_ENV` | Passed to the container for Rails-compatible tooling compatibility | no | — | helm/deployment |
| `DEPLOYMENT_ENV` | Identifies the deployment platform at runtime | no | — | helm/deployment |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. No feature flag system is configured.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/clients.yml` | YAML | Per-environment allowlist of valid `client_id` values used to authenticate API callers |
| `config/messagebus.yml` | YAML (ERB-interpolated) | Message Bus cluster connection settings and the whitelisted topic destination list |
| `config/logger.yml` | YAML | Per-environment log level (`DEBUG` for all environments) |
| `config/thin.yml` | YAML | Thin HTTP server settings: port (`9393`), daemonise flag, log path |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Kubernetes deployment defaults: replica counts, HPA config, probes, resource limits, log config |
| `.meta/deployment/cloud/components/app/<env>.yml` | YAML | Per-environment Kubernetes overrides: cloud provider, region, VPC, env vars, replica bounds |

### config/clients.yml — Structure

```yaml
development:
  - sample_client_id
staging:
  - "webbus-Ly9cLi4vXFw="
  - "salesforce-aGVsbG9fY2hyaXNfYmxhbmQ="
  - "test"
production:
  - "webbus-Ly9cLi4vXFw="
  - "salesforce-aGVsbG9fY2hyaXNfYmxhbmQ="
```

### config/messagebus.yml — Key settings

| Setting | Staging | Production |
|---------|---------|-----------|
| Producer address | `mbus-stg-na.us-central1.mbus.stable.gcp.groupondev.com:61613` | `mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com:61613` |
| Receipt wait timeout | 3000 ms | 6000 ms |
| Connection lifetime | 300 s | 300 s |
| Log level | `info` | `info` |
| Auto-init connections | true | true |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `WEBBUS_MESSAGEBUS_USER` | STOMP username for Message Bus cluster | k8s-secret (Conveyor Cloud) |
| `WEBBUS_MESSAGEBUS_PASSWORD` | STOMP password for Message Bus cluster | k8s-secret (Conveyor Cloud) |

> Secret values are NEVER documented. Secrets are managed via the `salesforce-cloud-secrets` repository and injected at deploy time by Conveyor Cloud.

## Per-Environment Overrides

| Environment | `ENV` value | Message Bus cluster | Min replicas | Max replicas |
|------------|-------------|---------------------|-------------|-------------|
| Development (local) | `development` | `localhost:61613` | — | — |
| Staging (GCP us-central1) | `staging` | `mbus-stg-na.us-central1.mbus.stable.gcp.groupondev.com` | 1 | 2 |
| Production (GCP us-central1) | `production` | `mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com` | 1 | 2 |
| Production (AWS us-west-1/2) | `production` | `mbus-prod-na` equivalent per region | varies | varies |
| Production (AWS eu-west-1) | `production` | `mbus-prod-na` equivalent per region | varies | varies |

The common Kubernetes deployment config sets a global default of `minReplicas: 2` and `maxReplicas: 15` with an HPA target utilisation of `100%`, but individual environment files may override these bounds (production-us-central1 sets `minReplicas: 1`, `maxReplicas: 2`).
