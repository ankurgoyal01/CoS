---
service: "argus"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

Argus has exactly one integration dependency: the Wavefront SaaS monitoring platform. All three job containers (`continuumArgusAlertSyncJob`, `continuumArgusDashboardSyncJob`, `continuumArgusSummaryReportJob`) talk exclusively to Wavefront's REST API. There are no internal Groupon service dependencies at runtime.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Wavefront (`https://groupon.wavefront.com`) | REST / HTTPS | Alert CRUD, dashboard submission, metric time-series queries | yes | `wavefront` (stub in architecture DSL) |

### Wavefront Detail

- **Protocol**: REST over HTTPS
- **Base URL**: `https://groupon.wavefront.com`
- **Auth**: Two auth mechanisms are used:
  - `Authorization: Bearer <token>` — for alert management endpoints (`/api/v2/alert`, `/api/v2/search/alert`)
  - `X-AUTH-TOKEN: <token>` — for chart and dashboard endpoints (`/chart/api`, `/api/dashboard`)
- **Purpose**: Central monitoring platform that stores and evaluates all Groupon production alerts and dashboards. Argus syncs YAML-defined alert configurations to Wavefront on every relevant commit to `master`.
- **Failure mode**: If Wavefront is unavailable, HTTP requests fail and Argus logs `Failure: create failed <status>` to stdout. The CI pipeline stage fails, and the previous Wavefront configuration remains intact. No retry logic is implemented.
- **Circuit breaker**: No evidence found in codebase. No circuit breaker is configured.

### Services Monitored (via Wavefront alert definitions)

The following Groupon services are monitored through alerts managed by Argus. Argus does not call these services directly; their metrics are queried indirectly from Wavefront.

| Service | Wavefront Source Tag | Alert Tag Prefix |
|---------|---------------------|-----------------|
| `api-lazlo` (SMA) | `source=api-lazlo` | `argus.prod.dub1.sma.api_lazlo` |
| `api-lazlo` (SOX) | `source=api-lazlo` (SOX env) | `argus.prod.dub1.sox.api_lazlo` |
| `api-proxy` | `source=api-proxy` | `argus.prod.dub1.api_proxy` |
| `deckard` | `source=deckard` | `argus.prod.dub1.sma.deckard` |
| `client-id` | `source=client-id` | `argus.prod.dub1.clientId` |
| `api-torii` | `source=api-torii` | `argus.prod.dub1.api_torii` |
| `regulatory-consent-log` | `source=regulatory-consent-log` | `argus.prod.dub1.regconsentlog` |
| `edge-proxy` | `source=edge-proxy` | `argus.prod.dub1.api_lazlo` (HB alerts) |

## Internal Dependencies

> No evidence found in codebase. Argus has no runtime dependencies on internal Groupon services.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Jenkins CI (`Jenkinsfile`) | Shell / Gradle task invocation | Triggers alert and dashboard sync jobs post-merge on `master` branch |
| Operators (manual) | Shell / Gradle task invocation | Ad-hoc alert or dashboard sync for specific environments |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

No automated health checks or retry mechanisms are implemented. If Wavefront API calls fail, Argus reports the HTTP status code to stdout and the CI stage is marked failed, providing an implicit signal that the sync did not complete.
