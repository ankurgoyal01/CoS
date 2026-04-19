---
service: "occasions-itier"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Occasions ITA (occasions-itier).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Occasion Page Render](occasion-page-render.md) | synchronous | HTTP GET from browser | Full-page render for `/occasion/:occasion` and related routes; aggregates deals, themes, and geo data |
| [Deal Pagination AJAX](deal-pagination-ajax.md) | synchronous | HTTP GET from browser (AJAX) | Returns next page of deal cards for an occasion via `/occasion/:occasion/deals/start/:offset` |
| [Cache Refresh Background](cache-refresh-background.md) | scheduled | Internal timer (every 1800s) | Polls Campaign Service and updates Memcached and in-process memory caches |
| [Manual Cache Control](manual-cache-control.md) | synchronous | Operator HTTP POST | Operator-triggered cache flush via `POST /cachecontrol` |
| [Embedded Cards Loader](embedded-cards-loader.md) | synchronous | HTTP GET from browser | Returns pre-rendered card HTML via `/occasion/embedded-cards-loader` for lazy injection |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The [Occasion Page Render](occasion-page-render.md) flow spans `continuumOccasionsItier`, `apiProxy` (Groupon V2 API), `continuumRelevanceApi` (RAPI), Alligator, `continuumGeoDetailsService`, and `continuumOccasionsMemcached`. It is referenced by the central architecture dynamic view `dynamic-occasion-request-flow`.
