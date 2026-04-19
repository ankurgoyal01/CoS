---
service: "optimus-prime-ui"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

Optimus Prime UI has two internal dependencies and one external dependency. All API traffic flows through the nginx reverse proxy embedded in the Docker container. The primary internal dependency is `optimus-prime-api`, which provides all domain data. A secondary internal dependency is `refresh-api--v2`, proxied under `/refresh-api/`. The single external dependency is Google Analytics for telemetry.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Analytics | HTTPS (gtag SDK) | User interaction tracking, error reporting, performance and web-vitals telemetry | no | `googleAnalytics` |

### Google Analytics Detail

- **Protocol**: HTTPS via the browser-native `gtag` JavaScript SDK
- **Base URL / SDK**: `gtag` global loaded at runtime; integration implemented in `src/utils` GA utility
- **Auth**: No authentication required (client-side SDK with Groupon's GA tracking ID)
- **Purpose**: Captures interaction events, Vue and window error exceptions, JavaScript heap memory usage, and Core Web Vitals (LCP, FID, CLS) for observability
- **Failure mode**: Telemetry is best-effort; analytics failures do not affect ETL pipeline management functionality
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| optimus-prime-api | HTTPS/JSON (reverse proxy via nginx `/api/`) | All ETL domain data: user profile, jobs, job runs, connections, workspaces, datafetchers, dataloaders, storage, metadata | `continuumOptimusPrimeApi` |
| refresh-api--v2 | HTTPS/JSON (reverse proxy via nginx `/refresh-api/`) | Refresh API operations forwarded to the refresh-api service | External stub (no Structurizr ID in this module) |

### optimus-prime-api Detail

- **Protocol**: HTTPS/JSON
- **Base URL**: Proxied via nginx to `https://optimus-prime-api.${ENV}.service` — the `ENV` variable is substituted at container start from the deployment environment variable
- **Auth**: User identity is established by the upstream SSO layer and injected into requests via nginx headers (`X-GRPN-USERNAME`, `X-GRPN-EMAIL`, etc.)
- **Purpose**: Backend-of-record for all ETL pipeline management operations; the UI is entirely dependent on this service for data
- **Failure mode**: UI displays a splash screen error or reconnect message when the API is unreachable; health check polling emits `onHealthCheckError` events
- **Circuit breaker**: No explicit circuit breaker; health check background task tracks outage duration and reports to Google Analytics

## Consumed By

> Upstream consumers are end users (Groupon internal data engineers and analysts) accessing the SPA via browser. No other services call this UI's endpoints programmatically. The service's deploybot dependency declaration lists `optimus-prime-api` and `conveyor-cloud` as dependencies, confirming the UI has no downstream API consumers of its own.

## Dependency Health

The `continuumOptimusPrimeUiBackgroundTasks` component runs browser-side timer loops that poll the backend's health endpoint. On health check failure, it emits an `onHealthCheckError` event. On recovery, it emits `onHealthCheckOk` and records the outage duration to Google Analytics as a `HealthCheck Failure` exception event. The UI shows a `ReconnectMessage` or `NetworkErrorSnackbar` to the user during connectivity loss.
