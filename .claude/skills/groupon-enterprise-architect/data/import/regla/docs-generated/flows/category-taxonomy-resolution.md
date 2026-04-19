---
service: "regla"
title: "Category Taxonomy Resolution"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "category-taxonomy-resolution"
flow_type: synchronous
trigger: "A rule condition evaluation or API query requires checking whether a category belongs to a category tree"
participants:
  - "reglaService"
  - "reglaRedisCache"
architecture_ref: "dynamic-containers-regla"
---

# Category Taxonomy Resolution

## Summary

This flow describes how regla resolves category hierarchy membership for rule condition evaluation. When a rule condition references a category tree (e.g., "deal must belong to category X or its descendants"), `reglaService` checks whether the target category is in the specified tree by calling `GET /categoryInCategoryTree`. The service first queries `reglaRedisCache` for a cached taxonomy tree; on a cache miss, it fetches the full category hierarchy from Taxonomy Service v2 and populates the cache. Cache entries are refreshed on a configurable `TAXONOMY_CACHE_SYNC_INTERVAL_SECONDS` interval (default 3600 seconds). This flow ensures high-throughput stream evaluation is not bottlenecked by remote taxonomy lookups.

## Trigger

- **Type**: api-call or internal
- **Source**: Either a downstream caller issuing `GET /categoryInCategoryTree`, or `reglaService` / `reglaStreamJob` internally evaluating a category-based rule condition
- **Frequency**: On-demand; high-frequency during stream processing when rules have category conditions

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (External System or Internal) | Requests category tree membership check | — |
| regla Service | Handles query; checks Redis cache; fetches from Taxonomy Service on miss | `reglaService` |
| regla Redis Cache | Caches full taxonomy tree data to avoid repeated remote calls | `reglaRedisCache` |
| Taxonomy Service v2 | Authoritative source for category hierarchy data | — |

## Steps

1. **Category check requested**: A caller sends `GET /categoryInCategoryTree?categoryId=<id>&treeId=<id>` to `reglaService`, or an internal rule evaluation triggers a category condition check.
   - From: Caller / Internal rule evaluation
   - To: `reglaService`
   - Protocol: REST/HTTP GET, API key auth (external callers)

2. **reglaService queries Redis for cached taxonomy tree**: Service constructs the cache key for the requested category tree and queries `reglaRedisCache`.
   - From: `reglaService`
   - To: `reglaRedisCache`
   - Protocol: Redis GET (jedis 2.8.0)

3a. **Cache hit path**: Redis returns the cached taxonomy tree data; service traverses the tree in memory to determine whether `categoryId` is a descendant of `treeId`.
   - From: `reglaRedisCache`
   - To: `reglaService`
   - Protocol: Redis response

3b. **Cache miss path**: Redis returns nil; service calls Taxonomy Service v2 to fetch the full category hierarchy.
   - From: `reglaService`
   - To: Taxonomy Service v2
   - Protocol: HTTP GET (commons-httpclient 3.1), URL configured via `TAXONOMY_SERVICE_URL`

4. **Taxonomy Service v2 returns category hierarchy**: Returns the category tree JSON for the requested tree.
   - From: Taxonomy Service v2
   - To: `reglaService`
   - Protocol: HTTP JSON response

5. **reglaService populates Redis cache**: Service writes the fetched taxonomy tree to `reglaRedisCache` with TTL derived from `REDIS_TTL_SECONDS` (403200s).
   - From: `reglaService`
   - To: `reglaRedisCache`
   - Protocol: Redis SET with TTL

6. **reglaService evaluates category membership**: Traverses the in-memory tree to determine whether `categoryId` is in `treeId`.
   - From: `reglaService` (internal)
   - To: `reglaService`
   - Protocol: In-memory tree traversal

7. **Returns result**: `reglaService` returns `{result: true|false}` to the caller.
   - From: `reglaService`
   - To: Caller
   - Protocol: REST/HTTP JSON

### Scheduled Cache Refresh (Background)

8. **Taxonomy cache refresh tick**: On each `TAXONOMY_CACHE_SYNC_INTERVAL_SECONDS` tick (default 3600s), `reglaService` proactively fetches updated taxonomy trees from Taxonomy Service v2 and refreshes Redis cache entries.
   - From: `reglaService` (scheduled internal job)
   - To: Taxonomy Service v2
   - Protocol: HTTP GET (commons-httpclient 3.1)

9. **Updated tree written to Redis**: Fresh taxonomy data replaces stale cache entries.
   - From: `reglaService`
   - To: `reglaRedisCache`
   - Protocol: Redis SET with TTL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Taxonomy Service v2 unreachable on cache miss | Service returns error or uses stale Redis data if available | Category check fails or returns stale result; rules with category conditions may evaluate incorrectly |
| Taxonomy Service v2 returns incorrect hierarchy | Incorrect tree data cached in Redis | Category conditions may misevaluate until `TAXONOMY_CACHE_SYNC_INTERVAL_SECONDS` elapses and cache is refreshed |
| Redis unavailable | Service attempts direct Taxonomy Service v2 call on every request | Higher latency on all category condition evaluations; load on Taxonomy Service v2 increases |
| Category or tree ID not found in hierarchy | Service returns `{result: false}` | Rule condition treats the category as not matching |
| `TAXONOMY_CACHE_SYNC_INTERVAL_SECONDS` too long | Stale taxonomy data used for extended period | Rules using updated category hierarchies may not reflect changes promptly |

## Sequence Diagram

```
Caller -> reglaService: GET /categoryInCategoryTree?categoryId=X&treeId=Y
reglaService -> reglaRedisCache: GET taxonomy:tree:Y
alt Cache hit
  reglaRedisCache --> reglaService: taxonomy tree data
else Cache miss
  reglaRedisCache --> reglaService: nil
  reglaService -> TaxonomyServiceV2: GET <TAXONOMY_SERVICE_URL>/category-tree/Y
  TaxonomyServiceV2 --> reglaService: category hierarchy JSON
  reglaService -> reglaRedisCache: SET taxonomy:tree:Y TTL=403200
end
reglaService -> reglaService: Traverse tree: is categoryId=X a descendant of Y?
reglaService --> Caller: {result: true|false}
```

## Related

- Related flows: [Rule Evaluation Query](rule-evaluation-query.md), [Stream Processing](stream-processing.md)
