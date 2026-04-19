---
service: "layout-service"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Layout Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Layout Request Flow](layout-request-flow.md) | synchronous | HTTP GET `/layout/*` from i-tier app | End-to-end request composition, template rendering, and response assembly |
| [Template Cache Miss Flow](template-cache-miss.md) | synchronous | Cache miss during template lookup | Compiles template from source, renders fragment, and populates Redis cache |
| [Asset Resolution Flow](asset-resolution.md) | synchronous | Template render requiring static asset URLs | Resolves CDN-backed asset URLs and injects them into the rendering context |
| [Context Composition Flow](context-composition.md) | synchronous | Inbound layout request with locale/market/user data | Assembles the full locale, market, and user context used by the template renderer |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Layout Request Flow (`dynamic-layout-service-request-flow`) is defined in the Structurizr architecture model and traces the runtime path from `layoutSvc_httpApi` through `layoutSvc_requestComposer`, `layoutSvc_templateRenderer`, and `layoutSvc_templateCacheClient`. This flow is the primary cross-component flow referenced in the central Continuum architecture model.

All flows are internal to `continuumLayoutService`. The only cross-container interaction is the Redis protocol call to `continuumLayoutTemplateCache` during template cache read/write operations (see [Template Cache Miss Flow](template-cache-miss.md)).
