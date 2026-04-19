---
service: "api-proxy"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, flexiconf]
---

# Configuration

## Overview

API Proxy is configured through a combination of environment variables, runtime configuration files loaded via the `flexiconf` library (version 0.1.0), and dynamic configuration reloaded at runtime via the `/config/*` admin endpoints. Route configuration and BEMOD routing overlays are loaded from external services (`continuumClientIdService`, BASS) at startup and refreshed on a background schedule. No Consul or Vault evidence found in the architecture model; secret management is assumed to follow Continuum platform conventions.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `REDIS_HOST` | Hostname of the `continuumApiProxyRedis` Redis instance | yes | None | env |
| `REDIS_PORT` | Port for Redis connection | yes | `6379` | env |
| `CLIENT_ID_SERVICE_URL` | Base URL for `continuumClientIdService` | yes | None | env |
| `BASS_SERVICE_URL` | Base URL for BASS Service used by `apiProxy_bemodSync` | yes | None | env |
| `RECAPTCHA_SECRET_KEY` | Site secret for Google reCAPTCHA API verification | yes | None | env / secret store |
| `METRICS_HOST` | Hostname or endpoint for the Metrics Stack | yes | None | env |
| `HTTP_PORT` | Port on which the Vert.x HTTP server listens | yes | `8080` | env |
| `CONFIG_RELOAD_INTERVAL_MS` | Millisecond interval between route config refresh cycles | no | Configured via flexiconf | env |
| `BEMOD_SYNC_INTERVAL_MS` | Millisecond interval between BASS BEMOD sync cycles | no | Configured via flexiconf | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| reCAPTCHA enforcement per path | Enables or disables reCAPTCHA validation on a specific route | off | per-route (via route config) |
| Rate limiting enabled | Enables global or client-level throttling enforcement | on | global / per-client |
| BEMOD routing overlays | Enables behaviour-modification routing rules loaded from BASS | on | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| Route configuration bundle | JSON / YAML (via flexiconf) | Defines route-to-destination mappings, filter directives, rate-limit policy, and reCAPTCHA-protected paths; loaded by `apiProxy_routeConfigLoader` |
| BEMOD overlay data | JSON (from BASS via bass-client) | Provides marked/blacklisted/whitelisted entries; refreshed by `apiProxy_bemodSync` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `RECAPTCHA_SECRET_KEY` | Google reCAPTCHA site secret used by `apiProxy_recaptchaClient` | env / platform secret store |
| `CLIENT_ID_SERVICE_CREDENTIALS` | Credentials for authenticating to `continuumClientIdService` | env / platform secret store |
| `BASS_SERVICE_CREDENTIALS` | Credentials for authenticating to BASS Service | env / platform secret store |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Configuration differs across environments primarily through environment variable values:

- **Development / local**: Smaller rate-limit windows and lower thresholds; reCAPTCHA validation typically disabled or using test keys; Redis may be a local instance
- **Staging**: Full configuration mirroring production topology; BEMOD sync enabled; uses staging `continuumClientIdService` endpoint
- **Production**: Full rate-limiting enforcement; live reCAPTCHA secret key; production Redis cluster; production BASS endpoint
