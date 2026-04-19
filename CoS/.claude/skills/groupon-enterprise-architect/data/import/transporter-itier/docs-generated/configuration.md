---
service: "transporter-itier"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files-cson, secrets-file-yaml, helm-values]
---

# Configuration

## Overview

Transporter I-Tier uses the ITier `keldor` / `keldor-config` configuration system. Configuration is layered: a base CSON file (`config/base.cson`) is overridden by node-env-specific files (`config/node-env/*.cson`) and then by stage-specific files (`config/stage/*.cson`). The active stage config is selected at runtime via the `KELDOR_CONFIG_SOURCE` environment variable. Salesforce OAuth2 client credentials are loaded from an external YAML secrets file whose path is defined in the stage config. Kubernetes deployment parameters (replica counts, resource limits, environment variables) are declared in `.deploy-configs/` YAML files managed by Napistrano and applied at deploy time via Helm.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the keldor configuration stage (`{production}` or `{staging}`) | yes | None | helm `envVars` in deploy config |
| `NODE_OPTIONS` | Node.js heap configuration; set to `--max-old-space-size=1024` to cap heap at 1 GB | yes | None | helm `envVars` in deploy config |
| `PORT` | HTTP listen port for the ITier server | yes | `8000` | helm `envVars` in deploy config |
| `UV_THREADPOOL_SIZE` | libuv async I/O thread pool size | yes | `75` | helm `envVars` in deploy config |
| `DEPLOY_ENV` | Runtime environment tag (`staging` or `production`); used by `/jtier-upload-proxy` middleware to resolve the jtier hostname | yes | Falls back to `localhost` in dev | Conveyor / Napistrano |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase.

The `itier-feature-flags` library (^3.1.3) is declared in `package.json` dependencies but no feature flag definitions or usages were identified in the application module code.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base configuration: sets `localization.package: false`, `steno.transport: file`, and service client global defaults |
| `config/node-env/development.cson` | CSON | Development environment overrides |
| `config/node-env/production.cson` | CSON | Production node-env override: enables `logging.log_tracky_to_file: true` |
| `config/node-env/test.cson` | CSON | Test environment overrides; sets `environment: test` mode for mock function dispatch |
| `config/stage/production.cson` | CSON | Production stage config: `jtierBaseUrl`, Salesforce `loginUrl`, `redirectUri`, CDN `hosts`, secrets file `pathToSecret`, `environment: cloud` |
| `config/stage/staging.cson` | CSON | Staging stage config: jtierBaseUrl points to `transporter-jtier.staging.service/v0`, staging Salesforce sandbox `loginUrl` |
| `.deploy-configs/values.yaml` | YAML | Base Napistrano/Helm values: service ID, log directory, filebeat resource limits |
| `.deploy-configs/production-us-west-1.yml` | YAML | Production AWS us-west-1 Kubernetes deploy config: replica counts, VIP, DNS names, env vars |
| `.deploy-configs/production-us-central1.yml` | YAML | Production GCP us-central1 Kubernetes deploy config |
| `.deploy-configs/production-eu-west-1.yml` | YAML | Production AWS eu-west-1 Kubernetes deploy config |
| `.deploy-configs/staging-us-central1.yml` | YAML | Staging GCP us-central1 Kubernetes deploy config |
| `.deploy-configs/staging-us-west-1.yml` | YAML | Staging AWS us-west-1 Kubernetes deploy config |
| `.deploy-configs/staging-us-west-2.yml` | YAML | Staging AWS us-west-2 Kubernetes deploy config |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `TRANSPORTER_ITIER_SF_CLIENT_ID` | Salesforce Connected App OAuth2 client ID (Base64-encoded in secrets YAML) | YAML secrets file at path from `config.secret.pathToSecret` |
| `TRANSPORTER_ITIER_SF_CLIENT_SECRET` | Salesforce Connected App OAuth2 client secret (Base64-encoded in secrets YAML) | YAML secrets file at path from `config.secret.pathToSecret` |

> Secret values are NEVER documented. Only names and rotation policies.

Secrets file paths (relative to the config directory):
- Production: `../../config/secrets/cloud/production-us-west-1.yml`
- Staging: `../../config/secrets/cloud/staging-us-west-1.yml`

Secrets are read at request time in `modules/upload_s3/actions.js` using `js-yaml` and decoded from Base64 before being passed to `jsforce.OAuth2`.

## Per-Environment Overrides

| Config Key | Development | Staging | Production |
|------------|-------------|---------|------------|
| `jtierBaseUrl` | `localhost:9000` (DEPLOY_ENV fallback) | `http://transporter-jtier.staging.service/v0` | `http://transporter-jtier.production.service/v0` |
| `connectedApp.loginUrl` | Not configured | `https://groupon-dev--staging.my.salesforce.com` | `https://login.salesforce.com` |
| `connectedApp.redirectUri` | Not configured | `https://transporter-staging.groupondev.com/oauth2/callback` | `https://transporter.groupondev.com/oauth2/callback` |
| `connectedApp.grant_type` | Not configured | `password` | `password` |
| `assets.hosts` | Not configured | `staging<1,2>.grouponcdn.com` | `www<1,2>.grouponcdn.com` |
| `environment` | `test` | `cloud` | `cloud` |
| `KELDOR_CONFIG_SOURCE` | Not set | `{staging}` | `{production}` |
