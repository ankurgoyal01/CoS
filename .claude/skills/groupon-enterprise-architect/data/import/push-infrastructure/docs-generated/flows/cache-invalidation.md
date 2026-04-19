---
service: "push-infrastructure"
title: "Cache Invalidation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "cache-invalidation"
flow_type: synchronous
trigger: "HTTP POST to /cache/invalidate"
participants:
  - "continuumPushInfrastructureService"
  - "externalRedisCluster_5b2e"
architecture_ref: "dynamic-cache-invalidation"
---

# Cache Invalidation

## Summary

The Cache Invalidation flow allows operators and automated processes to remove stale template entries from the Redis template cache. When a message template is updated in the backing template store, any cached copy in Redis will be out of date until it expires naturally or is explicitly invalidated. Callers submit a POST to `/cache/invalidate` with the target templateId (or a pattern); Push Infrastructure executes a Redis DEL operation to remove the cache entry, ensuring the next render request triggers a fresh fetch and re-population of the cache with the updated content.

## Trigger

- **Type**: api-call
- **Source**: Template management system (on template update), operator tooling, or CI/CD pipeline step
- **Frequency**: On-demand, following template content updates

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Template management system / operator | Initiates cache invalidation after template update | — |
| Push Infrastructure Service | Receives invalidation request, executes Redis DEL | `continuumPushInfrastructureService` |
| Redis Cluster | Target cache — entries removed by DEL operation | `externalRedisCluster_5b2e` |

## Steps

1. **Receive invalidation request**: Caller submits HTTP POST to `/cache/invalidate` with the templateId (or list of templateIds) to invalidate
   - From: `template management system / operator`
   - To: `continuumPushInfrastructureService`
   - Protocol: REST / HTTP

2. **Resolve cache key(s)**: Constructs the Redis cache key(s) for the target template(s) using the pattern `template_cache:{templateId}`
   - From: `continuumPushInfrastructureService`
   - To: `continuumPushInfrastructureService` (internal)
   - Protocol: internal

3. **Delete from Redis cache**: Executes Redis DEL for each resolved cache key, removing the stale template entry
   - From: `continuumPushInfrastructureService`
   - To: `externalRedisCluster_5b2e`
   - Protocol: Redis (jedis)

4. **Return invalidation confirmation**: Returns HTTP 200 with count of cache entries deleted
   - From: `continuumPushInfrastructureService`
   - To: `template management system / operator`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| templateId not found in cache | Redis DEL returns 0 (key not present); treated as success | HTTP 200 returned; no stale entry to remove |
| Redis DEL failure | Return HTTP 500; log error | Cache entry not removed; stale template may continue to be served until TTL expiry or retry |
| Invalid / missing templateId in request | Return HTTP 400 | No cache operation performed |

## Sequence Diagram

```
TemplateManagementSystem -> continuumPushInfrastructureService: POST /cache/invalidate {templateId: "some-template-id"}
continuumPushInfrastructureService -> continuumPushInfrastructureService: Resolve key: template_cache:some-template-id
continuumPushInfrastructureService -> externalRedisCluster_5b2e: DEL template_cache:some-template-id
externalRedisCluster_5b2e --> continuumPushInfrastructureService: (integer) 1  [key deleted]
continuumPushInfrastructureService --> TemplateManagementSystem: HTTP 200 {invalidated: 1}

[Next render request after invalidation]
continuumPushInfrastructureService -> externalRedisCluster_5b2e: GET template_cache:some-template-id
externalRedisCluster_5b2e --> continuumPushInfrastructureService: nil  [cache miss]
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: SELECT updated template content
externalTransactionalDatabase_3f1a --> continuumPushInfrastructureService: updated templateSource
continuumPushInfrastructureService -> externalRedisCluster_5b2e: SETEX template_cache:some-template-id {TTL} {updatedTemplateSource}
```

## Related

- Architecture dynamic view: `dynamic-cache-invalidation`
- Related flows: [Template Rendering](template-rendering.md), [Message Processing and Delivery](message-processing-delivery.md)
