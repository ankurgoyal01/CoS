---
service: "optimus-prime-ui"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values, build-args]
---

# Configuration

## Overview

Optimus Prime UI is configured through three mechanisms: Docker build arguments baked into the compiled static assets at image build time (via a `.env` file consumed by Vite), runtime environment variables injected into the nginx configuration via `envsubst` at container startup, and per-environment Helm values files under `.meta/deployment/cloud/components/app/`. No external config store (Consul, Vault) is used for this frontend service.

## Environment Variables

### Runtime (nginx template substitution — injected at container start)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENV` | Selects the target environment name used in nginx proxy URLs (`https://optimus-prime-api.${ENV}.service`) | yes | none | helm (`envVars` in deployment YAML) |
| `MODE` | Secondary mode selector used in nginx template (e.g., `prod`, `stable`) | yes | none | helm (`envVars` in deployment YAML) |

### Build-time (Docker build arguments — embedded in Vite bundle)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `VITE_BUILD_REF` | Git commit ref of the build; surfaced in the UI footer version component | no | `not-set` | Docker `--build-arg build_ref` |
| `VITE_BUILD_DATE` | Date of the build; surfaced in the UI footer version component | no | `not-set` | Docker `--build-arg build_date` |
| `VITE_RELEASE` | Semantic version of the release; surfaced in the UI footer version component | no | `not-set` | Docker `--build-arg release` |

### nginx Header Variables (set from upstream SSO layer)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `$http_x_grpn_username` | Groupon SSO username injected by the SSO proxy | yes | — | nginx `$http_x_grpn_username` |
| `$http_x_grpn_email` | Groupon SSO user email | yes | — | nginx header |
| `$http_x_grpn_firstname` | Groupon SSO user first name | yes | — | nginx header |
| `$http_x_grpn_lastname` | Groupon SSO user last name | yes | — | nginx header |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase for feature flag configuration. The `NODE_ENV === 'test'` check in `src/main.js` activates MSW mock service worker for local testing.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `nginx.conf` | nginx | Reverse proxy configuration, static file serving, gzip, security headers, cookie injection, health endpoint |
| `.meta/deployment/cloud/components/app/common.yml` | YAML (Helm values) | Shared deployment configuration: Docker image name, port (8080/8081), HPA (min 1 / max 2 / target 50%) |
| `.meta/deployment/cloud/components/app/dev-us-west-2.yml` | YAML (Helm values) | Dev environment overrides: `ENV=staging`, `MODE=stable`, 1 replica, custom subdomain |
| `.meta/deployment/cloud/components/app/staging-us-west-2.yml` | YAML (Helm values) | Staging US-West-2 overrides: `ENV=staging`, `MODE=stable`, 2 replicas |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML (Helm values) | Staging GCP US-Central1 overrides |
| `.meta/deployment/cloud/components/app/production-us-west-2.yml` | YAML (Helm values) | Production US-West-2 overrides: `ENV=production`, `MODE=prod`, 2–3 replicas |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML (Helm values) | Production GCP US-Central1 overrides |
| `.deploy_bot.yml` | YAML | Deploybot pipeline configuration: staging and production targets, Kubernetes contexts, promote paths |

## Secrets

> No evidence found in codebase for secrets managed by this service. The `.meta/.raptor.yml` declares `secret_path` as empty. Backend connection credentials (database passwords, SFTP keys) are managed by `optimus-prime-api`, not the UI.

## Per-Environment Overrides

| Environment | `ENV` value | `MODE` value | Replicas |
|-------------|-------------|--------------|----------|
| dev-us-west-2 | `staging` | `stable` | 1 |
| staging-us-west-2 | `staging` | `stable` | 2 |
| staging-us-central1 | (from staging YAML) | (from staging YAML) | 2 |
| production-us-west-2 | `production` | `prod` | 2–3 |
| production-us-central1 | (from prod YAML) | (from prod YAML) | per prod YAML |

The `ENV` variable controls which environment's `optimus-prime-api` instance nginx proxies to at `https://optimus-prime-api.${ENV}.service`.
