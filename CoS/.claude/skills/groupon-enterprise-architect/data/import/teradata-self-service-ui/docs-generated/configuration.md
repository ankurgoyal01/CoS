---
service: "teradata-self-service-ui"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, build-args, nginx-env-subst, api-response]
---

# Configuration

## Overview

Configuration for this service comes from three sources:

1. **Docker build arguments** — baked into the container image at build time via a `.env` file that Vue CLI reads during `yarn build`.
2. **Runtime environment variables** — injected into the Nginx container at startup; used by `envsubst` to template the Nginx config (specifically `$ENV` and `$MODE`).
3. **API-sourced configuration** — the application fetches a `/api/v1/configuration` response from `teradata-self-service-api` at runtime, which provides operational parameters (password expiry, lock duration, Jira base URL).

## Environment Variables

### Build-time (Docker build arguments → `.env` file)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `VUE_APP_BUILD_REF` | Git SHA of the build; displayed in application footer for traceability | no | `not-set` | Docker build arg `build_ref` |
| `VUE_APP_BUILD_DATE` | ISO 8601 timestamp of the build; displayed in application footer | no | `not-set` | Docker build arg `build_date` |
| `VUE_APP_RELEASE` | Semantic version tag of the release (e.g., `1.2.0`); displayed in application footer | no | `not-set` | Docker build arg `release` |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

### Runtime (injected into Nginx container via Kubernetes)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENV` | Deployment environment name used in the Nginx `proxy_pass` service-discovery hostname (`teradata-self-service-api.${ENV}.service`) | yes | — | Kubernetes deployment (`envVars` in `.meta/deployment/cloud/`) |
| `MODE` | Deployment mode identifier (e.g., `prod`, `stable`) | yes | — | Kubernetes deployment (`envVars` in `.meta/deployment/cloud/`) |

## Feature Flags

> No evidence found in codebase. No feature flag system is configured.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `nginx.conf` | Nginx config | Nginx server block: port 8080, gzip, security headers, cookie injection from SSO headers, `/api/` proxy_pass, `/grpn/healthcheck` endpoint |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes deployment config: image name, replica count, port 8080 (http), admin port 8081 |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production overrides: GCP `prod` VPC, `us-central1`, replicas 2–10, CPU 80m request, memory 200Mi/500Mi |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging overrides: GCP `stable` VPC, `us-central1`, replicas 1–5, CPU 50m request, memory 100Mi/500Mi |
| `.deploy_bot.yml` | YAML | Deploybot configuration: staging and production Kubernetes targets, Slack channel `#dnd-tools-ops`, promote-to chain |

## Secrets

> No evidence found in codebase. The `.meta/.raptor.yml` `secret_path` field is empty. Authentication is handled upstream by the corporate SSO proxy; no application-level secrets are managed in this repository.

## Per-Environment Overrides

| Parameter | Staging | Production |
|-----------|---------|------------|
| `ENV` env var | `staging` | `production` |
| `MODE` env var | `stable` | `prod` |
| VPC | `stable` | `prod` |
| Min replicas | 1 | 2 |
| Max replicas | 5 | 10 |
| CPU request | 50m | 80m |
| Memory request | 100Mi | 200Mi |
| Memory limit | 500Mi | 500Mi |
| VIP URL | `teradata-self-service-ui.staging.service.us-central1.gcp.groupondev.com` | `teradata-self-service-ui.us-central1.conveyor.prod.gcp.groupondev.com` |

## API-Sourced Runtime Configuration

The application calls `GET /api/v1/configuration` on startup and stores the result in the Vuex `configuration` state. Known fields (from mock fixture `src/mocks/api/v2/configuration.json`):

| Field | Type | Purpose |
|-------|------|---------|
| `lockDurationInHours` | integer | Number of hours a Teradata account remains locked after being locked |
| `passwordExpiryInDays` | integer | Number of days after which a Teradata password expires (displayed in the account password warning) |
| `jiraBaseUrl` | string | Base URL for constructing Jira ticket links from `jiraKey` values in request records |
| `uiUrl` | string | The public URL of this UI (used by the backend for callback/link generation) |
