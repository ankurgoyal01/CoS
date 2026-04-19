---
service: "deal"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Deal Page.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Page Load](deal-page-load.md) | synchronous | Consumer HTTP request to `/deals/:deal-permalink` | SSR rendering with parallel API calls to assemble and return the full deal page |
| [Deal Purchase](deal-purchase.md) | synchronous | Consumer clicks "Buy" / "Add to Cart" on deal page | Submits deal to cart via internal AJAX API and Groupon V2 Cart endpoint |
| [Cache Refresh](cache-refresh.md) | scheduled | Akamai TTL expiry / scheduled invalidation | CDN cache invalidation triggers fresh render of deal page |
| [AB Test Variant Assignment](ab-test-variant-assignment.md) | synchronous | Each deal page request | Experimentation Service assigns and applies A/B test variants per consumer |
| [Asset Build and Deploy](asset-build-deploy.md) | batch | CI/CD pipeline trigger (code merge) | Webpack compiles deal page static assets and deploys them via Docker/Kubernetes |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **Deal Page Load** flow spans `dealWebApp` → Groupon V2 APIs → GraphQL APIs → Experimentation Service → Online Booking Service. See [Deal Page Load](deal-page-load.md).
- The **Deal Purchase** flow spans `dealWebApp` → Groupon V2 Cart API → downstream order creation. See [Deal Purchase](deal-purchase.md).
- Cross-service dynamic views are tracked in the central Continuum architecture model.
