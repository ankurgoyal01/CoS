---
service: "sub_center"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

sub_center follows standard Continuum I-Tier configuration patterns: environment variables provide runtime credentials and service URLs, while itier-server config files supply framework-level settings. Feature flag evaluation is delegated to the Feature Flags Service at runtime rather than managed through static config.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `TWILIO_ACCOUNT_SID` | Twilio account identifier for SMS delivery | yes | none | env / vault |
| `TWILIO_AUTH_TOKEN` | Twilio authentication token for SMS delivery | yes | none | env / vault |
| `GROUPON_V2_API_URL` | Base URL for the Groupon V2 API | yes | none | env |
| `GSS_SERVICE_URL` | Base URL for the GSS Service | yes | none | env |
| `SUBSCRIPTIONS_SERVICE_URL` | Base URL for the Subscriptions Service | yes | none | env |
| `GEO_DETAILS_SERVICE_URL` | Base URL for the GeoDetails Service | yes | none | env |
| `REMOTE_LAYOUT_SERVICE_URL` | Base URL for the Remote Layout Service | yes | none | env |
| `FEATURE_FLAGS_SERVICE_URL` | Base URL for the Feature Flags Service | yes | none | env |
| `OPTIMIZE_SERVICE_URL` | Base URL for the Optimize Service | yes | none | env |
| `MEMCACHED_HOSTS` | Comma-separated Memcached host:port list | yes | none | env |
| `NODE_ENV` | Runtime environment (development, staging, production) | yes | none | env |
| `PORT` | HTTP port the server listens on | no | 3000 | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above. Actual values are stored in Vault or the Continuum secrets store.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Evaluated at runtime | Feature flags are fetched from `featureFlagsService_ext_8e0b` at request time | — | per-request |

> No static feature flag names are defined in the architecture model. Flag names and defaults are managed in the Feature Flags Service. See [Integrations](integrations.md) for integration details.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/default.json` | JSON | Default itier-server settings (inferred from I-Tier conventions) |
| `config/production.json` | JSON | Production environment overrides (inferred from I-Tier conventions) |

> Config file paths are inferred from standard itier-server project conventions. Verify against the service source repository.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `TWILIO_ACCOUNT_SID` | Authenticates Twilio SDK for SMS delivery | vault |
| `TWILIO_AUTH_TOKEN` | Authenticates Twilio SDK for SMS delivery | vault |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

Standard Continuum I-Tier environments: development, staging (itier), and production. Service URLs and Memcached hosts differ per environment. Feature flag evaluations may return different results per environment based on flag configuration in the Feature Flags Service. Twilio credentials differ between staging (test/sandbox credentials) and production.
