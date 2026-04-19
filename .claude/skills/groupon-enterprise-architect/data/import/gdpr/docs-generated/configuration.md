---
service: "gdpr"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars, helm-values]
---

# Configuration

## Overview

The GDPR service is configured primarily through a TOML file (`config/config.toml`) that must be present at runtime. The file is explicitly excluded from the Docker image and is injected at deploy time via Kubernetes secrets. One environment variable (`GIN_MODE`) is set in the Dockerfile. Kubernetes resource limits and port mappings are defined in Helm values files under `.meta/deployment/cloud/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GIN_MODE` | Sets Gin web framework operating mode | Yes | `release` | Dockerfile (`ENV GIN_MODE=release`) |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/config.toml` | TOML | Primary runtime configuration — defines all service hosts, API keys, client IDs, agent IDs, and SMTP email settings. Injected via Kubernetes secrets at deploy time; not committed to the repository. |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Helm values for Kubernetes deployment — image name, replica counts, CPU/memory requests and limits, port configuration |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging (GCP europe-west1) environment overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging (GCP us-central1) environment overrides |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production (AWS eu-west-1) environment overrides |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production (GCP europe-west1) environment overrides |

### `config/config.toml` Structure

The TOML configuration file contains the following sections:

| Section | Key | Purpose |
|---------|-----|---------|
| `[user]` | `agent_id_emea` | Agent ID for EMEA Cyclops instance |
| `[user]` | `agent_id_nam` | Agent ID for NAM Cyclops instance |
| `[user]` | `agent_email` | Default agent email address |
| `[token_service]` | `client_id` | OAuth client ID for token service |
| `[token_service]` | `api_key` | API key for authenticating to token service |
| `[token_service]` | `host` | Hostname of `cs-token-service` |
| `[lazlo]` | `client_id` | Client ID passed as query parameter to Lazlo API |
| `[lazlo]` | `host` | Hostname of `api-lazlo` |
| `[consumer_data_service]` | `host` | Hostname of `consumer-data-service` |
| `[consumer_data_service]` | `api_key` | API key for `consumer-data-service` (`X-API-KEY` header) |
| `[ugc]` | `host` | Hostname of `ugc-api-jtier` |
| `[ugc]` | `place_service_host` | Hostname of `m3-placeread` |
| `[ugc]` | `place_service_client_id` | Client ID for `m3-placeread` API |
| `[subscription_service]` | `host` | Hostname of `global-subscription-service` |
| `[email]` | `host` | SMTP relay hostname |
| `[email]` | `port` | SMTP relay port |
| `[email]` | `from` | From address for GDPR result emails |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `config/config.toml` (at runtime) | Contains all API keys, client IDs, agent IDs, and SMTP configuration | k8s-secret (injected via `.meta/deployment/cloud/secrets/{env}.yml` at deploy time) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging environments** (GCP `europe-west1`, GCP `us-central1`): Use `staging-europe-west1.yml` and `staging-us-central1.yml` Helm value overrides; share the same `common.yml` base. Kubernetes namespace: `gdpr-staging`.
- **Production EU** (AWS `eu-west-1`): Uses `production-eu-west-1.yml` overrides. Kubernetes namespace: `gdpr-production`.
- **Production EMEA** (GCP `europe-west1`): Uses `production-europe-west1.yml` overrides. Kubernetes namespace: `gdpr-production`.
- **Production US** (GCP `us-central1`): Uses `production-us-central1.yml` overrides. Kubernetes namespace: `gdpr-production`.

All environments use the same Docker image (`docker-conveyor.groupondev.com/aaa/gdpr`) with version controlled by `DEPLOYBOT_PARSED_VERSION` at deploy time.
