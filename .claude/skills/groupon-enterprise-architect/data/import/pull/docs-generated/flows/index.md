---
service: "pull"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Pull — Homepage, Search, Browse, and Local listing discovery for Groupon web.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Homepage Render](homepage-render.md) | synchronous | HTTP GET `/` from consumer browser or mobile client | Orchestrates homepage card and layout assembly via Homepage Orchestrator, then renders and returns a full HTML page |
| [Browse, Search, and Local Request](browse-search-local.md) | synchronous | HTTP GET `/browse`, `/search`, `/local`, `/goods`, or `/gifting` from consumer client | Resolves geo and feature flags, fetches relevance data and supporting content, and renders a discovery listing page |
| [Wishlist Sync](wishlist-sync.md) | synchronous | Homepage or listing page render for a signed-in user | Reads wishlist state from Wishlist Service during SSR to render wishlist indicators on deal cards |
| [Telemetry Emission](telemetry-emission.md) | synchronous | Every HTTP request handled by Page Controllers | Emits per-request metrics, traces, and error telemetry to the observability platform via Telemetry Publisher |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Browse/Search Request**: Spans `continuumPullItierApp`, `continuumBirdcageService`, `continuumGeoPlacesService`, `continuumRelevanceApi`, `continuumLayoutService`, and `apiProxy`. Documented in the central architecture dynamic view `dynamic-pull-browse-request-flow`. See [Browse, Search, and Local Request](browse-search-local.md).
- **Homepage Render**: Spans `continuumPullItierApp`, `continuumBirdcageService`, `apiProxy`, and `continuumLayoutService`. See [Homepage Render](homepage-render.md).
- **Wishlist Sync**: Spans `continuumPullItierApp` and `continuumWishlistService`. See [Wishlist Sync](wishlist-sync.md).
