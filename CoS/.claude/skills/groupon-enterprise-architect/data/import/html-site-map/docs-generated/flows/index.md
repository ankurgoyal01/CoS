---
service: "html-site-map"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for HTML Sitemap.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Sitemap Home Page Request](sitemap-home-page-request.md) | synchronous | HTTP GET `/sitemap` | User or crawler requests the top-level state/region sitemap page; service fetches state crosslinks from LPAPI and renders HTML |
| [Sitemap Cities Page Request](sitemap-cities-page-request.md) | synchronous | HTTP GET `/sitemap/{regionSlug}` | User or crawler requests the cities listing for a region; service fetches city crosslinks from LPAPI and renders HTML |
| [Sitemap Categories Page Request](sitemap-categories-page-request.md) | synchronous | HTTP GET `/sitemap/{regionSlug}/{citySlug}` | User or crawler requests deal categories for a city; service fetches category crosslinks from LPAPI and renders HTML |
| [Error Page Rendering](error-page-rendering.md) | synchronous | LPAPI returns non-200 / unknown slug | Service renders the custom 404 page when a region or city slug is not recognized |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in this service cross into `continuumApiLazloService` (LPAPI) for data retrieval and into the Remote Layout service for page shell composition. See [Integrations](../integrations.md) for dependency details.

No dynamic views are currently modeled in the Structurizr DSL for this service (`views/dynamics.dsl` is empty).
