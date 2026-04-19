---
service: "occasions-itier"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumOccasionsItier, continuumOccasionsMemcached]
---

# Architecture Context

## System Context

occasions-itier is a Continuum platform web application that sits between browser-based end users and a set of internal Groupon APIs. Users navigate to occasion browsing pages; the service aggregates deals, themes, and merchandising data from upstream services and returns fully-rendered HTML pages or deal JSON fragments. It is part of the Continuum commerce stack alongside the Relevance API, Deal Catalog Service, and GeoDetails Service.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Occasions ITA Web App | `continuumOccasionsItier` | Web App | Node.js / I-Tier / Express | 16.x / 7.14.2 / 4.18.2 | Serves occasion browsing pages; coordinates upstream API calls and cache reads |
| Occasions Memcached | `continuumOccasionsMemcached` | Cache | Memcached | — | Caches campaign configs and deal responses to reduce upstream API load |

## Components by Container

### Occasions ITA Web App (`continuumOccasionsItier`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Occasion Page Router | Handles incoming HTTP requests; dispatches to page handlers for `/occasions`, `/occasion/:occasion`, `/collection/:occasion`, `/:permalink_base` | Express 4.18.2 / itier-server |
| Deal Pagination Handler | Handles AJAX requests for paginated deal slices via `/occasion/:occasion/deals/start/:offset` and `/occasion/deals-json` | Express / itier-server |
| Embedded Cards Loader | Serves pre-rendered card HTML via `/occasion/embedded-cards-loader` for lazy-loading injection | Express / itier-server |
| Campaign Service Poller | Background task that polls Campaign Service (ArrowHead) every 1800 seconds; stores results in Memcached and in-process memory | itier-campaign-service-client 1.2.1 |
| Cache Control Handler | `GET /cachecontrol` and `POST /cachecontrol` endpoints for manual cache invalidation by operators | Express / itier-cached |
| Division / Theme Manager | Maintains in-process map of division configurations and occasion themes | itier-divisions 7.2.6 |
| SSR Renderer | Renders Preact components server-side for initial HTML delivery | preact 8.5.2 / keldor 7.3.7 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumOccasionsItier` | `continuumOccasionsMemcached` | Reads/writes campaign and deal caches | Memcached binary protocol |
| `continuumOccasionsItier` | `apiProxy` | Fetches deal data from Groupon V2 API via proxy | REST / HTTPS |
| `continuumOccasionsItier` | `continuumRelevanceApi` | Retrieves ranked deal recommendations (RAPI) | REST / HTTPS |
| `continuumOccasionsItier` | `continuumDealCatalogService` | Fetches deal catalog data | REST / HTTPS |
| `continuumOccasionsItier` | `continuumGeoDetailsService` | Resolves geo context for the requesting user | REST / HTTPS |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuumOccasionsItier`
- Dynamic view: `dynamic-occasion-request-flow`
