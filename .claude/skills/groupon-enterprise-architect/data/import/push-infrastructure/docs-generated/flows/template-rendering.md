---
service: "push-infrastructure"
title: "Template Rendering"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "template-rendering"
flow_type: synchronous
trigger: "HTTP POST to /render_template, or internal render call during message processing"
participants:
  - "continuumPushInfrastructureService"
  - "externalRedisCluster_5b2e"
architecture_ref: "dynamic-template-rendering"
---

# Template Rendering

## Summary

The Template Rendering flow handles the resolution, caching, and FreeMarker-based rendering of message templates. It is invoked both as a standalone REST endpoint (`/render_template`) for external callers who need a preview or pre-rendered content, and internally during the [Message Processing and Delivery](message-processing-delivery.md) flow. The service checks the Redis template cache first; on a cache miss, it fetches the template from the template store, populates the cache, and then performs the FreeMarker merge. The rendered output is returned to the caller or used directly for dispatch.

## Trigger

- **Type**: api-call (external) or direct (internal during queue processing)
- **Source**: External callers via `POST /render_template`; internal queue processor workers
- **Frequency**: Per message delivery; also on-demand for previews

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (external or internal) | Submits render request with templateId and data context | — |
| Push Infrastructure Service | Resolves template, executes FreeMarker render | `continuumPushInfrastructureService` |
| Redis Cluster | Template cache — serves pre-fetched templates; stores newly fetched templates | `externalRedisCluster_5b2e` |

## Steps

1. **Receive render request**: Caller provides templateId and data context payload (user variables, campaign variables, personalisation data)
   - From: `caller`
   - To: `continuumPushInfrastructureService`
   - Protocol: REST / HTTP (external) or direct call (internal)

2. **Check Redis template cache**: Performs Redis GET for key `template_cache:{templateId}`
   - From: `continuumPushInfrastructureService`
   - To: `externalRedisCluster_5b2e`
   - Protocol: Redis (jedis)

3. **Cache hit path — use cached template**: If the template is found in Redis, retrieves template source and proceeds directly to rendering
   - From: `externalRedisCluster_5b2e`
   - To: `continuumPushInfrastructureService`
   - Protocol: Redis (jedis)

4. **Cache miss path — fetch and populate cache**: If not in Redis, fetches template content from the backing template store (database or template service); stores in Redis with configured TTL
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a` (or template store)
   - Protocol: JDBC / HTTP

4b. **Populate Redis cache**: Stores fetched template in Redis for subsequent requests
   - From: `continuumPushInfrastructureService`
   - To: `externalRedisCluster_5b2e`
   - Protocol: Redis SETEX (jedis)

5. **Execute FreeMarker render**: Merges template source with supplied data context using FreeMarker 2.3.20; produces final rendered string (HTML for email, plain text for SMS, JSON payload for push)
   - From: `continuumPushInfrastructureService`
   - To: `continuumPushInfrastructureService` (FreeMarker engine — internal)
   - Protocol: internal

6. **Return rendered content**: Returns rendered output to the caller
   - From: `continuumPushInfrastructureService`
   - To: `caller`
   - Protocol: REST / HTTP (external) or return value (internal)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Template not found in cache or backing store | Return HTTP 404 or internal error | Render fails; message marked as FAILED if in queue processing context |
| FreeMarker syntax error in template | Catch render exception; log error | Return HTTP 500 or internal error; message marked FAILED |
| Data context missing required variable | FreeMarker renders with default/null; or throws if strict mode | May produce partial render or error depending on template strictness |
| Redis GET failure | Fall through to backing store fetch | Increased latency; delivery continues |
| Redis SET failure (cache populate) | Log warning; continue without caching | Next request will re-fetch from backing store; no functional impact |

## Sequence Diagram

```
Caller -> continuumPushInfrastructureService: POST /render_template {templateId, dataContext}
continuumPushInfrastructureService -> externalRedisCluster_5b2e: GET template_cache:{templateId}
externalRedisCluster_5b2e --> continuumPushInfrastructureService: (cache miss) nil

[cache miss path]
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: SELECT template WHERE id={templateId}
externalTransactionalDatabase_3f1a --> continuumPushInfrastructureService: templateSource
continuumPushInfrastructureService -> externalRedisCluster_5b2e: SETEX template_cache:{templateId} {TTL} {templateSource}
externalRedisCluster_5b2e --> continuumPushInfrastructureService: OK

[render]
continuumPushInfrastructureService -> continuumPushInfrastructureService: FreeMarker.process(templateSource, dataContext) -> renderedContent
continuumPushInfrastructureService --> Caller: HTTP 200 {renderedContent}
```

## Related

- Architecture dynamic view: `dynamic-template-rendering`
- Related flows: [Message Processing and Delivery](message-processing-delivery.md), [Cache Invalidation](cache-invalidation.md)
