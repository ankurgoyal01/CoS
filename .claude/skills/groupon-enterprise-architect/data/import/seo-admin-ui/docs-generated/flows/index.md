---
service: "seo-admin-ui"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for SEO Admin UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Landing Page Route CRUD](landing-page-route-crud.md) | synchronous | Operator action in admin UI | Create, read, update, or delete landing page routes via LPAPI |
| [Canonical Update](canonical-update.md) | synchronous | Operator action in admin UI | Submit and track canonical URL update tasks |
| [SEO Deal Attributes](seo-deal-attributes.md) | synchronous | Operator action in admin UI | Manage SEO-specific attributes for deal pages using Deal Catalog and SEO Deal API |
| [URL Removal Request](url-removal-request.md) | synchronous | Operator action in admin UI | Submit URL de-indexing requests to Google Search Console |
| [Auto-Index Worker](auto-index-worker.md) | scheduled | Schedule / manual trigger | Automatically submit pages to Google Search Console for indexing |
| [Page Route Auditing](page-route-auditing.md) | synchronous | Operator action in admin UI | Audit live page routes against expected routing table |
| [Crosslinks Analysis](crosslinks-analysis.md) | synchronous | Operator action in admin UI | Query and visualise the page crosslinks graph from Neo4j using D3 |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **Auto-Index Worker** flow crosses into Google Search Console API (external); see [Auto-Index Worker](auto-index-worker.md).
- The **SEO Deal Attributes** flow crosses into both Deal Catalog (GAPI) and SEO Deal API; see [SEO Deal Attributes](seo-deal-attributes.md).
- The **Landing Page Route CRUD** flow delegates persistence to LPAPI; see [Landing Page Route CRUD](landing-page-route-crud.md).
