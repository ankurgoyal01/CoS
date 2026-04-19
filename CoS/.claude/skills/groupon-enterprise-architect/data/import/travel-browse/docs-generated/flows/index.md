---
service: "travel-browse"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for travel-browse (Getaways Browse Web App).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Browse Page Render](browse-page-render.md) | synchronous | HTTP GET from browser/CDN to `/travel/:geo_slug/hotels` | Full SSR pipeline: route, fetch, cache, render, and return an HTML Getaways browse page |
| [Market-Rate Inventory Fetch](market-rate-inventory-fetch.md) | synchronous | HTTP GET from browser/CDN to `/hotels/:dealId/inventory` | Fetches real-time hotel availability and pricing from MARIS and Getaways API, renders inventory page |
| [TripAdvisor Reviews Fetch](tripadvisor-reviews-fetch.md) | synchronous | HTTP GET to `/getaways/tripadvisor` | Retrieves TripAdvisor review data for a hotel property via Getaways API and returns widget payload |
| [Client-Side Experimentation](client-side-experimentation.md) | synchronous | SSR request lifecycle — flag evaluation on every page render | Evaluates A/B experiment assignments and feature flags via Optimize Service before page render |
| [Localization and i18n](localization-i18n.md) | synchronous | SSR request lifecycle — locale resolution on every request | Resolves request locale from Accept-Language header and applies i18n translations to page content |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in travel-browse are contained within the `continuumGetawaysBrowseWebApp` container boundary with outbound REST calls to downstream Continuum services. The browse-page-render and market-rate-inventory-fetch flows span the most external dependencies and are the most operationally significant.

- Browse page render involves: `rapiApi`, `continuumGetawaysApi`, `geodetailsV2Api`, `lpapiPages`, `grouponV2Api`, `memcacheCluster`, `userAuthService`, `remoteLayoutService`, `optimizeService`, `grouponCdn`
- Market-rate inventory fetch involves: `marisApi`, `continuumGetawaysApi`, `memcacheCluster`
- TripAdvisor reviews fetch involves: `continuumGetawaysApi`

See [Architecture Context](../architecture-context.md) for the full container relationship map and [Integrations](../integrations.md) for dependency details.
