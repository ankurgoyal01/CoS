---
service: "mbus-sigint-frontend"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 2
---

# Integrations

## Overview

The service has two internal Groupon service dependencies, both accessed via HTTPS/JSON through Gofer clients on the Node.js backend. There are no external (third-party) integrations. The `mbus-sigint-config` dependency is critical — the entire UI is non-functional without it. The `service-portal` dependency provides supplementary service-name autocomplete data and degrades gracefully (retries every 5 seconds on the client).

## External Dependencies

> No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `mbus-sigint-config` | HTTPS/JSON (gofer proxy) | Primary API backend — serves cluster configuration, change requests, deploy schedules, and admin actions | `continuumMbusSigintConfigurationService` |
| `service-portal` | HTTPS/JSON (gofer proxy) | Provides list of all Groupon service names for autocomplete when submitting a change request | `servicePortal` |

### mbus-sigint-config Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `http://mbus-sigint-config.staging.service` (staging), `http://mbus-sigint-config.production.service` (production) — resolved via `@grpn/base-urls`
- **Auth**: Okta session forwarded via Hybrid Boundary headers
- **Purpose**: Serves all MessageBus configuration data and processes change requests, delete requests, deploy schedule management, and ad-hoc deployment triggers
- **Failure mode**: UI displays no configuration data; change request submission fails with an error visible to the user
- **Circuit breaker**: No evidence found — Gofer provides timeout-based failure; browser client retries every 5 seconds on bootstrap load failures

### service-portal Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `http://service-portal.staging.service` (staging), `http://service-portal.production.service` (production) — resolved via `@grpn/base-urls`
- **Auth**: `GRPN-Client-Id: mbus-sigint-frontend` header appended on all outbound requests
- **Purpose**: Supplies the full list of Groupon service names used for the service-name autocomplete field in the change request form
- **Failure mode**: Service name autocomplete is unavailable; user must type the service name manually; browser client retries every 5 seconds
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model. The service is accessed by internal Groupon engineers via browsers at `https://mbus.groupondev.com` (production) and `https://mbus-sigint-staging.groupondev.com` (staging).

## Dependency Health

Both upstream Gofer clients resolve base URLs dynamically via `@grpn/base-urls` based on the `KELDOR_CONFIG_SOURCE` environment variable (`{staging}` or `{production}`). On the browser side, the `api.js` service module retries failed bootstrap calls (app config, session info, clusters, service names) every 5 seconds with `setTimeout`. No circuit breaker or exponential backoff is implemented.
