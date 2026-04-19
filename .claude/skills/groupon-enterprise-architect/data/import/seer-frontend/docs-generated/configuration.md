---
service: "seer-frontend"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values]
---

# Configuration

## Overview

Seer Frontend is configured through a small set of environment variables injected at deploy time via Helm values (`.meta/deployment/cloud/components/app/`), plus a single compile-time constant (`BASE_HTTP_URL`) baked into the JavaScript bundle. No consul, vault, or runtime config-service integration is present in this codebase.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENV` | Runtime environment identifier (`staging` or `production`) | yes | none | helm env-vars (`.meta/deployment/cloud/components/app/staging-us-central1.yml`, `production-us-central1.yml`) |
| `MODE` | Cluster VPC mode (`stable` for staging) | yes | none | helm env-vars (`.meta/deployment/cloud/components/app/staging-us-central1.yml`) |

> IMPORTANT: No actual secret values are documented. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase. No feature-flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/constants.js` | JavaScript (ESM) | Defines `BASE_HTTP_URL = "/api"` — the root path prefix for all backend API calls |
| `vite.config.js` | JavaScript (ESM) | Build and dev-server configuration; defines `/api` reverse-proxy target for local development |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Helm values: Docker image, replica counts (min 1, max 2), HPA target 50%, HTTP port 8080 |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging (GCP us-central1) overrides: `cloudProvider: gcp`, `deployEnv: staging`, `region: us-central1`, `vpc: stable` |
| `.meta/deployment/cloud/components/app/staging-us-west-1.yml` | YAML | Staging (AWS us-west-1) overrides |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production (GCP us-central1) overrides: `cloudProvider: gcp`, `deployEnv: production`, `region: us-central1`, `vpc: prod` |
| `.meta/deployment/cloud/components/app/production-us-west-1.yml` | YAML | Production (AWS us-west-1) overrides |

## Secrets

> No evidence found in codebase. The `.meta/.raptor.yml` declares `secret_path:` as empty, indicating no secrets are configured via the Raptor secrets system for this service.

## Per-Environment Overrides

- **Development**: `vite.config.js` proxy routes `/api` requests to `http://seer-service.staging.service.us-central1.gcp.groupondev.com`, rewriting the path by stripping the `/api` prefix.
- **Staging**: `ENV=staging`, `MODE=stable`. GCP cluster `gcp-stable-us-central1` or AWS cluster `stable-us-west-1`. Filebeat volume type `low`.
- **Production**: `ENV=production` (note: production-us-central1.yml currently sets `ENV: staging` — likely a configuration bug), `vpc: prod`. GCP cluster `gcp-production-us-central1` or AWS cluster `production-us-west-1`.
