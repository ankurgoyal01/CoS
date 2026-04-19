---
service: "mbus-sigint-frontend"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

Configuration is managed through a layered CSON file system provided by `keldor-config`, with environment variable overrides injected at runtime via Helm. The base configuration is in `config/base.cson`; it is overridden by `config/node-env/{NODE_ENV}.cson` (controlling logging and asset modes) and then by `config/stage/{STAGE}.cson` (controlling environment-specific URLs and service client endpoints). The runtime Kubernetes environment injects a small set of environment variables to control Node.js memory, port, and config source selection.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the keldor-config stage profile (`{production}` or `{staging}`); drives which base URLs service clients resolve to | Yes | None | helm |
| `NODE_OPTIONS` | Node.js runtime flags — sets `--max-old-space-size=1024` to cap the V8 heap | Yes | None | helm |
| `PORT` | HTTP port the iTier server listens on | Yes | `8000` | helm |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O — set to `75` in all environments | Yes | None | helm |
| `NODE_ENV` | Activates node-env config layer (development, production, test) | No | `production` in containers | runtime |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase. The `itier-feature-flags` library is a dependency but no specific flags are defined in the application source.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base configuration: asset CDN hosts, steno transport, service client global defaults |
| `config/node-env/development.cson` | CSON | Development overrides (local asset server, relaxed settings) |
| `config/node-env/production.cson` | CSON | Production overrides: enables file-based tracky logging |
| `config/node-env/test.cson` | CSON | Test environment overrides |
| `config/stage/production.cson` | CSON | Production stage: Jira base URL (`https://jira.groupondev.com`), Service Portal base URL (`https://services.groupondev.com`), CDN hosts (`www<1,2>.grouponcdn.com`), service client base URL `{production}` |
| `config/stage/staging.cson` | CSON | Staging stage: Jira base URL (`https://jira-staging.groupondev.com`), Service Portal base URL (`http://service-portal-staging.snc1`), service client base URL `{staging}` |
| `.deploy-configs/values.yaml` | YAML | Helm chart base values (service ID, log configuration, filebeat resource limits) |
| `.deploy-configs/production-us-central1.yml` | YAML | Production GCP us-central1 Helm overrides (replicas 3–100, memory 2048Mi/4096Mi, HB ingress/egress) |
| `.deploy-configs/staging-us-central1.yml` | YAML | Staging GCP us-central1 Helm overrides (replicas 1–3, memory 2048Mi/4096Mi) |

## Secrets

> No evidence found in codebase. The `secretEnvVars` and `secretFiles` fields in all deploy config files are empty arrays/objects.

## Per-Environment Overrides

| Setting | Staging | Production |
|---------|---------|------------|
| App name | `MessageBus STAGING` | `MessageBus` |
| Jira base URL | `https://jira-staging.groupondev.com` | `https://jira.groupondev.com` |
| Service Portal base URL | `http://service-portal-staging.snc1` | `https://services.groupondev.com` |
| `KELDOR_CONFIG_SOURCE` | `{staging}` | `{production}` |
| `mbus-sigint-config` URL | `http://mbus-sigint-config.staging.service` | `http://mbus-sigint-config.production.service` |
| `service-portal` URL | `http://service-portal.staging.service` | `http://service-portal.production.service` |
| Min replicas | 1 | 3 |
| Max replicas | 3 | 100 |
| Asset CDN hosts | `staging<1,2>.grouponcdn.com` | `www<1,2>.grouponcdn.com` |
