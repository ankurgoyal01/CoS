---
service: "sponsored-campaign-itier"
title: Configuration
generated: "2026-03-02"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The service is configured via environment variables injected at container startup and CSON-format config files (`config/base.cson` and environment-specific overlays). Keldor is used as the config environment selector. Feature flags are evaluated at runtime via `itier-feature-flags` against the Birdcage service (`continuumBirdcageService`). No Vault or Consul configuration store was identified in the inventory.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Keldor config environment selector — determines which config stage overlay is loaded | yes | — | env |
| `NODE_OPTIONS` | Node.js runtime flags — sets heap memory limit | yes | `--max-old-space-size=1024` | env |
| `PORT` | HTTP server listening port | no | `8000` | env |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for I/O concurrency | no | `75` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

Feature flags are evaluated via `itier-feature-flags` against `continuumBirdcageService` at request time.

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `restrictInternalUsersFeature.enabled` | Controls access for internal-only (Groupon employee) merchant accounts | — | per-tenant |
| `preLaunchFeature.enabled` | Enables pre-launch test mode for campaigns before public availability | — | per-tenant |
| `smallBudgetFeature.enabled` | Allows merchants to create low-budget campaigns below the standard minimum | — | per-tenant |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base configuration shared across all environments |
| `config/stage/production.cson` | CSON | Production environment overrides |
| `config/stage/staging.cson` | CSON | Staging environment overrides |

## Secrets

> No evidence found — secret references (OAuth tokens, API keys) are managed externally. Secret names and rotation policies are to be documented by the service owner.

## Per-Environment Overrides

- **Production**: `config/stage/production.cson` overrides applied — targets production UMAPI and API proxy endpoints
- **Staging**: `config/stage/staging.cson` overrides applied — targets staging UMAPI and API proxy endpoints
- Environment selection is driven by the `KELDOR_CONFIG_SOURCE` environment variable at container startup
