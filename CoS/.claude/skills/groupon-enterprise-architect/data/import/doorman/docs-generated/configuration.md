---
service: "doorman"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "helm-values"]
---

# Configuration

## Overview

Doorman uses a layered YAML configuration approach managed by the `EnvConfig` class. Configuration files are stored under `config/` in per-environment subdirectories (e.g., `config/production-us-central1/`). The `RACK_ENV` environment variable selects the active environment. `EnvConfig` merges a base `config/` file with an environment-specific override file, providing dot-notation access. Three configuration domains exist: `saml.yml` (IdP settings), `destinations.yml` (registered token destinations), and `users_service.yml` (Users Service connection).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RACK_ENV` | Selects the active environment configuration directory under `config/` | yes | `development` | helm / env |
| `custom_logfile` | Overrides the log file name (default: `doorman.log`) | no | `doorman.log` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. Doorman does not implement feature flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/<env>/saml.yml` | YAML | Configures the SAML SP: `doorman_host` (ACS base URL) and `identity_provider_url` (Okta SSO endpoint) |
| `config/<env>/destinations.yml` | YAML | Registry of allowed destination tools; each entry maps a `destination_id` to `destination_host` and `destination_path` |
| `config/<env>/users_service.yml` | YAML | Users Service connection: `server` (base URL), `api_key`, `timeout` (ms), `user_agent` |
| `config/puma.rb` | Ruby | Puma web server: port 3180, 5 threads, 2 workers, `preload_app!` |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Kubernetes deployment defaults: image, replicas, ports, resource limits, health check paths |
| `.meta/deployment/cloud/components/app/<env>.yml` | YAML | Per-environment Kubernetes overrides: `RACK_ENV`, replica counts, cloud provider, region, namespace |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `api_key` (in `users_service.yml`) | X-Api-Key header authenticating Doorman to Users Service | k8s-secret / config file |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Doorman is deployed to the following environments, each with its own configuration subdirectory:

| Environment | Config Directory | `RACK_ENV` Value | Notes |
|-------------|-----------------|------------------|-------|
| Development | `config/development/` | `development` | Local dev; points to Okta dev app, localhost Users Service |
| Staging NA | `config/staging-us-central1/` | `staging-us-central1` | GCP us-central1 staging; broader destination set |
| Staging EMEA | `config/staging-europe-west1/` | `staging-europe-west1` | GCP europe-west1 staging |
| Production NA | `config/production-us-central1/` | `production-us-central1` | GCP us-central1 production; full destination registry |
| Production EU | `config/production-europe-west1/` | `production-europe-west1` | GCP europe-west1 production |
| Production EU (AWS) | `config/production-eu-west-1/` | `production-eu-west-1` | AWS eu-west-1 production (legacy) |

Key differences between environments:
- `saml.yml` `identity_provider_url` uses different Okta application IDs per environment.
- `destinations.yml` is scoped per region/environment; staging environments include additional test and UAT destinations not present in production.
- `users_service.yml` `server` URL points to the corresponding regional Users Service endpoint.
- Production Users Service timeout is 2000 ms; development is 10000 ms.
