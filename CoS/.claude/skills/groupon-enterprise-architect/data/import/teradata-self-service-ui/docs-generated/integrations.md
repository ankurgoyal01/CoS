---
service: "teradata-self-service-ui"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

The Teradata Self Service UI has one internal dependency (`teradata-self-service-api`) and one external dependency (Google Analytics). The backend API is accessed via a Nginx reverse proxy using service-discovery DNS. Google Analytics is called directly from the browser using the `gtag` SDK.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Analytics | HTTPS (gtag SDK) | User interaction tracking, API timing metrics, exception reporting, Core Web Vitals | no | `googleAnalytics` |

### Google Analytics Detail

- **Protocol**: HTTPS via browser `window.gtag()` global (Google Tag script loaded in `public/index.html`)
- **Base URL / SDK**: `window.gtag` global injected by Google Tag Manager / Analytics script; tracking ID sourced from `window.GA_TRACKING_ID`
- **Auth**: None (public telemetry endpoint)
- **Purpose**: Records page views on each Vue Router navigation; records user interactions (`gaInteraction`); records API call durations (`gaTiming`) for all seven API operations; records application and API exceptions (`gaException`); records Core Web Vitals (CLS, FID, LCP, FCP, TTFB) via the `web-vitals` library
- **Failure mode**: Non-critical. If Google Analytics is unreachable (e.g., ad-blocker, network issue), the application continues to function normally. Analytics events are fire-and-forget with no error propagation.
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| teradata-self-service-api | HTTPS (REST, proxied) | All Teradata account data: user profiles, account lists, credential management, request lifecycle, app configuration | `teradataSelfServiceApi` (stub in DSL) |

### teradata-self-service-api Detail

- **Protocol**: HTTPS REST. The Nginx server running in the same container proxies all `/api/` path requests to `https://teradata-self-service-api.${ENV}.service` using service-discovery DNS. Proxy timeouts are 300 seconds for read, connect, and send.
- **Auth**: The `user-id` HTTP header (populated from the `tss-user` cookie) is forwarded with every request to identify the caller.
- **Purpose**: Authoritative source for all Teradata account data. The UI has no direct database access.
- **Failure mode**: Critical. If the API is unavailable, the application displays a network error notification and all data views are empty. There is no offline fallback.
- **Circuit breaker**: No circuit breaker is implemented at the UI layer. Axios timeout behaviour applies; proxy timeouts are 300 seconds.

## Consumed By

> Upstream consumers are tracked in the central architecture model. This is a user-facing web application accessed via browser by authenticated Groupon employees.

## Dependency Health

The Nginx `/grpn/healthcheck` endpoint returns `200 ok` without calling the backend API, so the UI pod can be healthy even when the API is degraded. API dependency health is not probed separately at the infrastructure level. The Vuex store `isLoading` flag gates all UI rendering until the initial data fetch sequence completes or fails.
