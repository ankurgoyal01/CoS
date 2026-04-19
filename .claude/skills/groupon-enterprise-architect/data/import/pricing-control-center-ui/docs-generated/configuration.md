---
service: "pricing-control-center-ui"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "helm-values"]
---

# Configuration

## Overview

The service uses a layered Keldor/CSON configuration system. Base configuration is in `config/base.cson`. Stage-specific overrides live in `config/stage/production.cson` and `config/stage/staging.cson`. Node environment overrides are in `config/node-env/`. At runtime, the active config source is selected by the `KELDOR_CONFIG_SOURCE` environment variable injected via Helm. Infrastructure-level configuration (resource limits, replica counts, environment variables) is managed through Napistrano-generated YAML files in `.deploy-configs/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the Keldor config environment (`{production}` or `{staging}`) | yes | None | Helm (`.deploy-configs/*.yml`) |
| `NODE_OPTIONS` | Node.js V8 flags; sets `--max-old-space-size=1024` to cap heap memory | yes | None | Helm (`.deploy-configs/*.yml`) |
| `PORT` | HTTP port the iTier server listens on | yes | `8000` | Helm (`.deploy-configs/*.yml`) |
| `UV_THREADPOOL_SIZE` | libuv thread pool size; set to `75` to increase concurrency for async I/O | yes | `75` | Helm (`.deploy-configs/*.yml`) |
| `DEPLOY_ENV` | Determines environment-specific Doorman redirect URLs (`staging` or `production`) | yes | None | Runtime process env (read in `modules/home/actions.js`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. The `itier-feature-flags` package (`^2.2.2`) is listed as a dependency, but no specific feature flag names or usages were found in the explored source files.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base configuration; disables birdcage and localize service clients; sets API client ID; configures CSRF ignored paths and steno transport |
| `config/stage/production.cson` | CSON | Production overrides; sets CDN asset hosts to `www<1,2>.grouponcdn.com`; sets `baseUrl` to `{production}` |
| `config/stage/staging.cson` | CSON | Staging overrides; sets CDN asset hosts to `staging<1,2>.grouponcdn.com`; sets `baseUrl` to `{staging}` |
| `config/node-env/production.cson` | CSON | Node environment production override; enables `log_tracky_to_file` |
| `config/node-env/development.cson` | CSON | Node environment development overrides |
| `config/node-env/test.cson` | CSON | Node environment test overrides |
| `.deploy-configs/production-us-central1.yml` | YAML | Napistrano-generated Helm values for production GCP us-central1 deployment |
| `.deploy-configs/staging-us-central1.yml` | YAML | Napistrano-generated Helm values for staging GCP us-central1 deployment |
| `.deploy-configs/values.yaml` | YAML | Shared Helm chart values (service ID, component, log configuration) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `secretEnvVars` | No secrets configured — field is empty in both deploy configs | Helm |
| `secretFiles` | No secret files configured — field is empty in both deploy configs | Helm |

## Per-Environment Overrides

| Setting | Development | Staging | Production |
|---------|-------------|---------|------------|
| `KELDOR_CONFIG_SOURCE` | `{development}` | `{staging}` | `{production}` |
| `assets.hosts` | Not set | `staging<1,2>.grouponcdn.com` | `www<1,2>.grouponcdn.com` |
| `serviceClient.globalDefaults.baseUrl` | Not set | `{staging}` | `{production}` |
| Doorman redirect URL | No redirect (guard skips non-staging/non-production) | `https://doorman-staging-na.groupondev.com/...` | `https://doorman-na.groupondev.com/...` |
| Kubernetes namespace | N/A | `pricing-control-center-ui-staging-sox` | `pricing-control-center-ui-production-sox` |
| Replica count | N/A | min 1 / max 3 | min 2 / max 3 |
| CSRF ignored paths | `/post-user-auth-token` (all envs) | Same | Same |
