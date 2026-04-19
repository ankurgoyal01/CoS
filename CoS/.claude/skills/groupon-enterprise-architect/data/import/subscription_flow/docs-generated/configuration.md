---
service: "subscription_flow"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, gconfig, helm-values]
---

# Configuration

## Overview

Subscription Flow is configured through a combination of environment variables injected at runtime and dynamic configuration fetched from the GConfig Service at bootstrap. Environment variables supply connection URLs and service identity. GConfig provides runtime-adjustable values including feature flags and A/B experiment variant assignments. There are no secrets or credentials to manage beyond the service's internal identity tokens.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `PORT` | HTTP port the Express server listens on | no | 3000 | env / helm |
| `NODE_ENV` | Node.js environment (production, staging, development) | yes | development | env |
| `LAZLO_API_URL` | Base URL for the Lazlo API Service | yes | none | helm |
| `GCONFIG_URL` | Base URL for the GConfig Service | yes | none | helm |
| `GROUPON_V2_API_URL` | Base URL for the Groupon V2 API | yes | none | helm |
| `SERVICE_NAME` | I-tier service name identifier used in logging and request headers | yes | subscription_flow | helm |
| `LOG_LEVEL` | Application log level (debug, info, warn, error) | no | info | env / helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `subscription_modal_variant` | Controls which subscription modal variant (A/B) is rendered | default | per-tenant / global |
| `subscription_flow_enabled` | Enables or disables the subscription modal rendering endpoint | enabled | global |

> Feature flags are managed in GConfig and not fully enumerable from the inventory. Service owners should maintain a flag registry in GConfig.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | json | npm dependencies and npm script definitions |
| `config/default.coffee` | CoffeeScript | Default application configuration values |
| `config/production.coffee` | CoffeeScript | Production environment overrides |

## Secrets

> No evidence found in codebase for secrets specific to this service. Subscription Flow is stateless and does not manage API keys for third-party systems. Internal service-to-service calls rely on network-level trust or forwarded session context.

## Per-Environment Overrides

Production connects to live Lazlo API, GConfig, and Groupon V2 API endpoints. Staging uses staging-tier versions of each dependency. Development uses local or mock endpoints. The `NODE_ENV` variable controls which environment-specific configuration overrides are loaded. GConfig experiment assignments differ per environment.
