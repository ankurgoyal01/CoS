---
service: "layout-service"
title: "Layout Request Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "layout-request-flow"
flow_type: synchronous
trigger: "HTTP GET /layout/* from an i-tier frontend application"
participants:
  - "layoutSvc_httpApi"
  - "layoutSvc_requestComposer"
  - "layoutSvc_templateRenderer"
  - "layoutSvc_templateCacheClient"
  - "layoutSvc_assetResolver"
  - "continuumLayoutTemplateCache"
architecture_ref: "dynamic-layout-service-request-flow"
---

# Layout Request Flow

## Summary

This is the primary end-to-end request flow for Layout Service. An i-tier frontend application sends an HTTP GET request to `/layout/*`. The service parses the request, composes locale/market/user context, renders the appropriate Mustache template (using a Redis-backed cache for compiled templates and fragments), resolves CDN asset URLs, and returns the assembled page chrome HTML to the caller.

## Trigger

- **Type**: api-call
- **Source**: Groupon i-tier frontend application (any Continuum consumer-facing app)
- **Frequency**: Per page request — on-demand for every page load that requires header/footer chrome

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| I-tier Frontend App | Caller — initiates the layout request | External to `continuumLayoutService` |
| HTTP API Endpoints | Entry point — receives and routes the inbound HTTP request | `layoutSvc_httpApi` |
| Request Composition | Context builder — assembles locale, market, user, and feature context | `layoutSvc_requestComposer` |
| Template Renderer | Renderer — compiles and renders Mustache templates with assembled context | `layoutSvc_templateRenderer` |
| Asset Resolver | Asset provider — resolves CDN-backed static asset URLs for template injection | `layoutSvc_assetResolver` |
| Template Cache Client | Cache accessor — reads and writes compiled templates and rendered fragments | `layoutSvc_templateCacheClient` |
| Layout Template Cache | Data store — Redis instance holding cached template artifacts | `continuumLayoutTemplateCache` |

## Steps

1. **Receives layout request**: I-tier app sends HTTP GET to `/layout/*` with locale, market, and session context in headers or query parameters.
   - From: I-tier Frontend App
   - To: `layoutSvc_httpApi`
   - Protocol: REST (HTTP)

2. **Parses request and collects context**: HTTP API Endpoints delegate to Request Composition to parse the inbound request and build the rendering context.
   - From: `layoutSvc_httpApi`
   - To: `layoutSvc_requestComposer`
   - Protocol: direct (in-process)

3. **Assembles locale, market, and user context**: Request Composition reads locale, market identifier, user/session data, and any feature signals from the request, producing a context object for the renderer.
   - From: `layoutSvc_requestComposer`
   - To: `layoutSvc_templateRenderer`
   - Protocol: direct (in-process)

4. **Resolves CDN asset URLs**: Asset Resolver provides resolved CDN-backed asset URLs and brand-specific resource metadata to the template renderer before rendering begins.
   - From: `layoutSvc_assetResolver`
   - To: `layoutSvc_templateRenderer`
   - Protocol: direct (in-process)

5. **Looks up compiled template in cache**: Template Renderer asks Template Cache Client for a cached compiled template matching the requested layout zone and locale.
   - From: `layoutSvc_templateRenderer`
   - To: `layoutSvc_templateCacheClient`
   - Protocol: direct (in-process)

6. **Reads from Redis cache**: Template Cache Client performs a Redis GET for the template cache key.
   - From: `layoutSvc_templateCacheClient`
   - To: `continuumLayoutTemplateCache`
   - Protocol: Redis protocol

7. **Renders page chrome**: Template Renderer compiles the template (on cache miss) or uses the cached version (on hit), applies the assembled context and asset URLs, and produces the final HTML fragment.
   - From: `layoutSvc_templateRenderer`
   - To: `layoutSvc_templateRenderer` (internal render step)
   - Protocol: direct

8. **Writes rendered artifact to cache** (on cache miss only): Template Cache Client writes the newly compiled template or rendered fragment back to Redis with a TTL.
   - From: `layoutSvc_templateCacheClient`
   - To: `continuumLayoutTemplateCache`
   - Protocol: Redis protocol

9. **Returns layout response**: HTTP API Endpoints return the rendered HTML fragment to the calling i-tier app with HTTP 200.
   - From: `layoutSvc_httpApi`
   - To: I-tier Frontend App
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis connection failure | Template Cache Client falls back to cache-miss behavior; rendering proceeds without cache | Layout response is returned successfully; performance is degraded |
| Redis cache miss | Template Renderer compiles template from source; result is written to cache | Normal response; slightly higher latency for this request |
| Template compilation error | Error propagated from `layoutSvc_templateRenderer`; HTTP 500 returned | I-tier app receives error; page chrome unavailable for this request |
| Missing context data (locale/market) | `layoutSvc_requestComposer` applies defaults or returns 400 for invalid requests | Graceful degradation or explicit error to caller |
| Asset resolution failure | `layoutSvc_assetResolver` returns fallback or empty asset metadata | Layout rendered without asset URLs; browser may fail to load static assets |

## Sequence Diagram

```
I-tier App          -> layoutSvc_httpApi:         GET /layout/*
layoutSvc_httpApi   -> layoutSvc_requestComposer: Parse request and collect context
layoutSvc_requestComposer -> layoutSvc_templateRenderer: Render page chrome (with context)
layoutSvc_assetResolver   -> layoutSvc_templateRenderer: Provide resolved asset URLs
layoutSvc_templateRenderer -> layoutSvc_templateCacheClient: Read/write compiled templates
layoutSvc_templateCacheClient -> continuumLayoutTemplateCache: Redis GET (cache lookup)
continuumLayoutTemplateCache --> layoutSvc_templateCacheClient: Cache hit / miss
layoutSvc_templateCacheClient --> layoutSvc_templateRenderer: Compiled template or nil
layoutSvc_templateRenderer --> layoutSvc_requestComposer: Rendered HTML fragment
layoutSvc_requestComposer  --> layoutSvc_httpApi: Layout response
layoutSvc_httpApi  --> I-tier App: HTTP 200 with rendered page chrome
```

## Related

- Architecture dynamic view: `dynamic-layout-service-request-flow`
- Related flows: [Template Cache Miss Flow](template-cache-miss.md), [Asset Resolution Flow](asset-resolution.md), [Context Composition Flow](context-composition.md)
