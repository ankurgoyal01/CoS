---
service: "checkout-reloaded"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, keldor]
---

# Configuration

## Overview

checkout-reloaded is configured primarily through environment variables injected at container startup by the Kubernetes/Conveyor deployment pipeline. Runtime feature flag configuration is sourced dynamically from Keldor via the `keldor-client` SDK, allowing behavior changes without redeployment. No static config files (YAML, TOML, etc.) are documented in the service inventory as primary configuration sources.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment mode (development/staging/production) | yes | — | env |
| `PORT` | HTTP port the service listens on | no | 3000 | env |
| `KELDOR_CONFIG_SOURCE` | Keldor config endpoint URL for feature flag retrieval | yes | — | env |
| `NODE_OPTIONS` | V8 memory and runtime flags (e.g., `--max-old-space-size`) | no | — | env |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O tuning | no | — | env |
| `API_PROXY_BASE_URL` | Base URL for the internal API proxy (`itier-groupon-v2-client`) | yes | — | env |
| `ADYEN_API_KEY` | Adyen server-side API key for payment authorization calls | yes | — | env (secret) |
| `ADYEN_MERCHANT_ACCOUNT` | Adyen merchant account identifier | yes | — | env (secret) |
| `ADYEN_CLIENT_KEY` | Adyen client-side key injected into the drop-in component | yes | — | env |
| `SESSION_SECRET` | Secret used to sign Express session cookies | yes | — | env (secret) |
| `LOG_LEVEL` | Logging verbosity (debug/info/warn/error) | no | info | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are recorded here.

## Feature Flags

Feature flags are served at runtime by Keldor and consumed via `keldor-client`.

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `checkout.newPaymentFlow` | Enables the revised payment orchestration pathway | off | global |
| `checkout.adyenDropIn` | Toggles the Adyen drop-in payment component on the checkout page | off | global |
| `checkout.postPurchaseUpsell` | Enables post-purchase upsell offer presentation after order confirmation | off | global |

## Config Files

> No evidence found in codebase. No static configuration files (YAML, JSON, TOML, or properties) are documented as primary configuration sources for this service.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `ADYEN_API_KEY` | Authenticates server-side calls to Adyen payment API | k8s-secret |
| `ADYEN_MERCHANT_ACCOUNT` | Identifies the Groupon merchant account with Adyen | k8s-secret |
| `SESSION_SECRET` | Signs Express session cookies to prevent tampering | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies are recorded here.

## Per-Environment Overrides

- **development**: `NODE_ENV=development`; local Keldor source or mocked flags; Adyen sandbox credentials; `LOG_LEVEL=debug`
- **staging**: `NODE_ENV=staging`; staging Keldor endpoint; Adyen test environment credentials; reduced replica count
- **production**: `NODE_ENV=production`; production Keldor endpoint; live Adyen credentials; HPA with 2–10 replicas across snc1, sac1, and dub1 regions; `LOG_LEVEL=info`
