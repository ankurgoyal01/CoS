---
service: "sem-gtm"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

`sem-gtm` has one external dependency (Google Tag Manager Cloud API) and one internal cross-container dependency (tagging server referencing the preview server URL). The service is intentionally minimal at the integration layer — all tag destination integrations (Google Analytics, Google Ads, etc.) are managed through the GTM workspace configuration in the Google Tag Manager UI, not through Groupon's codebase.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Tag Manager Cloud API | HTTPS | Loads GTM container configuration, processes tag events, routes to tag destinations | yes | `gtmApiUnknown_ab3a36` (stub) |

### Google Tag Manager Cloud API Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Resolved at runtime via `CONTAINER_CONFIG` encoded credential bundle; upstream GTM Cloud infrastructure managed by Google
- **Auth**: `CONTAINER_CONFIG` environment variable containing a base64-encoded token that includes GTM container ID and authorization credentials
- **Purpose**: Provides the tag execution runtime — the GTM Cloud image communicates with Google's platform to load tag configuration, execute tag logic, and forward data to configured destinations (Google Analytics, Google Ads, and other marketing platforms)
- **Failure mode**: If the GTM Cloud API is unreachable at startup, the container will fail its readiness probe (`/healthz`) and will not receive traffic until connectivity is restored. In-flight requests may be dropped.
- **Circuit breaker**: No evidence found in codebase of a Groupon-managed circuit breaker; failure behavior is governed by the GTM Cloud image internals.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| GTM Preview Server (`sem-gtm::preview`) | HTTPS | Tagging server routes debug/preview sessions to the preview server via `PREVIEW_SERVER_URL` | `continuumSemGtmPreviewServer` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The tagging server is consumed by Groupon web and app clients that route tag requests to the server-side GTM endpoint. The preview server is consumed by tag engineers via the GTM UI debug/preview interface.

## Dependency Health

The tagging server's `PREVIEW_SERVER_URL` is statically configured to `https://gtm.groupon.com/preview/`. If the preview server is unreachable, only tag debugging and preview functionality is affected — production tag processing continues uninterrupted. Health of the GTM Cloud API dependency is surfaced indirectly through the `/healthz` probe; no dedicated dependency health endpoint is defined in this repository.
