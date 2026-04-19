---
service: "api-proxy"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 3
---

# Integrations

## Overview

API Proxy has two external dependencies (Google reCAPTCHA, BASS Service) and three internal Continuum dependencies (Client ID Service, Redis, Metrics Stack), plus a dynamic set of backend destination services resolved at runtime via route configuration. All integrations are synchronous; no message-bus dependencies exist.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google reCAPTCHA API | HTTPS | Verifies reCAPTCHA assessment tokens on protected request paths | no | — |
| BASS Service | HTTPS (bass-client 0.1.24) | Provides BEMOD (behaviour-modification) data — marked, blacklisted, and whitelisted routing overlays | yes | — |

### Google reCAPTCHA API Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Google reCAPTCHA verification endpoint (called via `apiProxy_recaptchaClient`)
- **Auth**: API key / site secret (configured via runtime config)
- **Purpose**: Validates reCAPTCHA tokens submitted with requests on paths that require bot protection
- **Failure mode**: If the reCAPTCHA endpoint is unreachable, requests requiring validation may be rejected or allowed depending on the configured fallback policy
- **Circuit breaker**: No evidence found

### BASS Service Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: bass-client 0.1.24 library
- **Auth**: Internal service credentials
- **Purpose**: Supplies BEMOD (behaviour-modification) data consumed by `apiProxy_bemodSync` to refresh routing overlays; controls which clients or paths are marked, blacklisted, or whitelisted
- **Failure mode**: If BASS is unavailable, the in-process BEMOD cache continues serving the last successfully loaded dataset until the next successful sync
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumClientIdService` | HTTPS | Provides client identity records and per-client policy configuration consumed by `apiProxy_clientIdLoader` | `continuumClientIdService` |
| `continuumApiProxyRedis` | RESP/TCP | Distributed rate-limit counter and throttling state store used by `apiProxy_rateLimiter` | `continuumApiProxyRedis` |
| `metricsStack` | TCP/HTTPS | Receives request metrics, structured logs, and distributed traces emitted by the proxy | `metricsStack` |
| Backend destination services (dynamic) | HTTPS | Target services to which matched requests are forwarded by `apiProxy_destinationProxy`; resolved at runtime from route configuration | — |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Legacy Android app | JSON/HTTPS | All mobile API requests are routed through API Proxy |
| Legacy iOS app | JSON/HTTPS | All mobile API requests are routed through API Proxy |
| Legacy web frontend | JSON/HTTPS | All web API requests are routed through API Proxy |
| Merchant Center | JSON/HTTPS | Merchant-facing API requests are routed through API Proxy |

> Upstream consumers are also tracked in the central architecture model (`structurizr/model/relations.dsl`).

## Dependency Health

- `continuumClientIdService`: polled periodically by `apiProxy_clientIdLoader`; in-process cache continues serving if the service is temporarily unreachable
- `continuumApiProxyRedis`: queried on every proxied request; Redis unavailability will impact rate-limiting enforcement
- BASS Service: polled on a background schedule by `apiProxy_bemodSync`; last known BEMOD state is preserved in memory between syncs
- Metrics Stack: fire-and-forget telemetry; failure to publish metrics does not affect request processing
- Backend destination services: failure propagated to the caller as an upstream error response
