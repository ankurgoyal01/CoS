---
service: "map_proxy"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for MapProxy.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Static Map Request (v2)](static-map-request-v2.md) | synchronous | HTTP GET to `/api/v2/static` | Provider-aware static map request: resolves provider by geography, builds signed URL, redirects caller to upstream image. |
| [Dynamic Map JavaScript Request (v2)](dynamic-map-js-request-v2.md) | synchronous | HTTP GET to `/api/v2/dynamic` | Provider-aware dynamic JS payload: resolves provider, composes JS from classpath templates, returns inline JavaScript to caller. |
| [Static Map Proxy Request (v1)](static-map-proxy-v1.md) | synchronous | HTTP GET to `/maps/api/staticmap` | Pass-through proxy: signs the incoming Google Static Maps request and redirects directly to Google Maps API. |
| [Provider Selection](provider-selection.md) | synchronous | Inbound map request (any endpoint) | Cross-cutting flow describing how MapProxy resolves which map provider (Google or Yandex) to use for a given request. |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The static map request flow is also modelled as a Structurizr dynamic view:
- Architecture dynamic view: `dynamic-map-proxy-static-request`

All flows terminate at one of two external systems (Google Maps API or Yandex Maps API) via HTTP 302 redirect, which the caller's browser or HTTP client follows directly. No other Groupon services are involved in the flows.
