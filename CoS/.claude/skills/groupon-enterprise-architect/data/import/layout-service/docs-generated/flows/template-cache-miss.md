---
service: "layout-service"
title: "Template Cache Miss Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "template-cache-miss"
flow_type: synchronous
trigger: "Cache lookup in continuumLayoutTemplateCache returns no entry for the requested template key"
participants:
  - "layoutSvc_templateRenderer"
  - "layoutSvc_templateCacheClient"
  - "continuumLayoutTemplateCache"
architecture_ref: "dynamic-layout-service-request-flow"
---

# Template Cache Miss Flow

## Summary

This flow describes what happens within Layout Service when a request for a compiled template or rendered fragment is not found in Redis. The Template Renderer compiles the Mustache template from source, renders the fragment using the assembled context, and then instructs the Template Cache Client to store the result in `continuumLayoutTemplateCache` for subsequent requests. This flow is a sub-flow of the [Layout Request Flow](layout-request-flow.md).

## Trigger

- **Type**: api-call (sub-flow triggered internally during layout request processing)
- **Source**: `layoutSvc_templateRenderer` — when `layoutSvc_templateCacheClient` returns a nil/empty result from Redis
- **Frequency**: Per cache miss — expected on cold start, after Redis flush, or after TTL expiry

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Template Renderer | Orchestrator — detects miss, compiles template, renders fragment | `layoutSvc_templateRenderer` |
| Template Cache Client | Cache accessor — performs Redis lookup and write-back | `layoutSvc_templateCacheClient` |
| Layout Template Cache | Data store — Redis instance targeted for lookup and population | `continuumLayoutTemplateCache` |

## Steps

1. **Requests template from cache**: Template Renderer sends a lookup request to Template Cache Client for the compiled template matching the current layout zone, locale, and market.
   - From: `layoutSvc_templateRenderer`
   - To: `layoutSvc_templateCacheClient`
   - Protocol: direct (in-process)

2. **Performs Redis GET**: Template Cache Client issues a Redis GET for the derived cache key.
   - From: `layoutSvc_templateCacheClient`
   - To: `continuumLayoutTemplateCache`
   - Protocol: Redis protocol

3. **Receives cache miss response**: Redis returns nil; Template Cache Client reports a miss to Template Renderer.
   - From: `continuumLayoutTemplateCache`
   - To: `layoutSvc_templateCacheClient`
   - Protocol: Redis protocol

4. **Compiles template from source**: Template Renderer loads the raw Mustache template source from the deployed artifact and compiles it using Hogan.
   - From: `layoutSvc_templateRenderer`
   - To: `layoutSvc_templateRenderer` (internal compilation step)
   - Protocol: direct

5. **Renders fragment with context**: Template Renderer applies the assembled context (locale, market, user, asset URLs) to the compiled template, producing the rendered HTML fragment.
   - From: `layoutSvc_templateRenderer`
   - To: `layoutSvc_templateRenderer` (internal render step)
   - Protocol: direct

6. **Writes compiled template and fragment to cache**: Template Cache Client stores the compiled template and/or rendered fragment in `continuumLayoutTemplateCache` with the configured TTL.
   - From: `layoutSvc_templateCacheClient`
   - To: `continuumLayoutTemplateCache`
   - Protocol: Redis protocol (SET with EX/TTL)

7. **Returns rendered fragment**: Template Renderer returns the rendered HTML fragment to its caller (`layoutSvc_requestComposer` within the parent layout request flow).
   - From: `layoutSvc_templateRenderer`
   - To: `layoutSvc_requestComposer`
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis GET fails (connection error) | Template Cache Client reports miss; Template Renderer proceeds to compile without cache | Template compiled and rendered successfully; write-back may also fail, resulting in no caching for this request |
| Redis SET fails on write-back | Error logged; rendering continues without caching the result | Fragment is returned to caller; cache remains unpopulated; next request will also be a miss |
| Template source file missing | Compilation error propagated; HTTP 500 returned | Layout response unavailable for this request |
| Hogan compilation error | Error propagated; HTTP 500 returned | Layout response unavailable; investigate template source integrity |

## Sequence Diagram

```
layoutSvc_templateRenderer  -> layoutSvc_templateCacheClient:   Lookup compiled template
layoutSvc_templateCacheClient -> continuumLayoutTemplateCache:   Redis GET (cache key)
continuumLayoutTemplateCache --> layoutSvc_templateCacheClient:  nil (cache miss)
layoutSvc_templateCacheClient --> layoutSvc_templateRenderer:    Cache miss
layoutSvc_templateRenderer  -> layoutSvc_templateRenderer:      Compile Mustache template from source
layoutSvc_templateRenderer  -> layoutSvc_templateRenderer:      Render fragment with context + asset URLs
layoutSvc_templateRenderer  -> layoutSvc_templateCacheClient:   Write compiled template/fragment
layoutSvc_templateCacheClient -> continuumLayoutTemplateCache:   Redis SET with TTL
continuumLayoutTemplateCache --> layoutSvc_templateCacheClient:  OK
layoutSvc_templateRenderer  --> layoutSvc_requestComposer:      Rendered HTML fragment
```

## Related

- Architecture dynamic view: `dynamic-layout-service-request-flow`
- Related flows: [Layout Request Flow](layout-request-flow.md), [Context Composition Flow](context-composition.md)
