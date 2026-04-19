---
service: "proximity-ui"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 1
---

# Integrations

## Overview

Proximity UI has a single internal dependency: `continuumProximityHotzoneApi`. All hotzone, campaign, category, and user data flows through this one downstream service. The integration pattern is synchronous HTTP proxy — every browser request that requires data is forwarded by the Express server to the upstream Hotzone API and the response is relayed back verbatim.

## External Dependencies

> No evidence found in codebase. There are no external (third-party or cloud) service integrations.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Continuum Proximity Hotzone API | HTTP (REST, GET/POST/DELETE) | Single source of truth for all hotzone, campaign, category, and user data. All four proxy components forward to this service. | `continuumProximityHotzoneApi` |

### Continuum Proximity Hotzone API Detail

- **Protocol**: HTTP REST
- **Base URL (production SNC1)**: `http://ec-proximity-vip.snc1/v1/proximity/location/hotzone`
- **Base URL (production DUB1)**: `http://ec-proximity-vip.dub1/v1/proximity/location/hotzone`
- **Base URL (production SAC1)**: `http://ec-proximity-vip.sac1/v1/proximity/location/hotzone`
- **Base URL (staging SNC1)**: `http://ec-proximity-app-staging-vip.snc1/v1/proximity/location/hotzone`
- **Base URL (staging EMEA)**: `http://proximity-emea-staging-vip.snc1/v1/proximity/location/hotzone`
- **Base URL (development)**: `http://localhost:9000/v1/proximity/location/hotzone`
- **Auth**: `client_id=ec-team` query parameter appended to every upstream request
- **Purpose**: Reads and writes all hotzone deals, campaigns, categories, and user allowlists
- **Failure mode**: Upstream HTTP error status codes are relayed directly to the browser; no retry or fallback is implemented
- **Circuit breaker**: No evidence found in codebase

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon EC-team Administrators | HTTPS (browser) | Manages proximity hotzones and campaigns via the web UI |

> Upstream consumers beyond internal administrators are tracked in the central architecture model.

## Dependency Health

No health check, retry, or circuit breaker patterns are implemented for the `continuumProximityHotzoneApi` dependency. Errors from the upstream are forwarded as-is to the browser client. The deployment verification script (`fabfile.py`) performs a single `curl` to `http://{host}:8080/#!/summary` post-deploy to confirm the app is serving.
