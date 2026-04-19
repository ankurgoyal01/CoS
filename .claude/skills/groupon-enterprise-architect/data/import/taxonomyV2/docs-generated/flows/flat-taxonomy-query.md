---
service: "taxonomyV2"
title: "Flat Taxonomy Hierarchy Query"
generated: "2026-03-03"
type: flow
flow_name: "flat-taxonomy-query"
flow_type: synchronous
trigger: "GET /taxonomies/{guid}/flat API call, optionally with If-Modified-Since header"
participants:
  - "continuumTaxonomyV2Service_restApi"
  - "continuumTaxonomyV2Service_requestFilters"
  - "continuumTaxonomyV2Service_cachingCore"
  - "continuumTaxonomyV2Service_postgresRepositories"
  - "continuumTaxonomyV2Redis"
  - "continuumTaxonomyV2Postgres"
architecture_ref: "components-continuum-taxonomy-v2-service-components-view"
---

# Flat Taxonomy Hierarchy Query

## Summary

This flow returns the full flattened category hierarchy for a given taxonomy — every category node in the tree, with depth, parent, children, attributes, locales, and relationship data. The endpoint has two dramatically different performance profiles depending on whether the consumer sends an `If-Modified-Since` header. With the header, the service performs a fast timestamp comparison against the cache (p99: 20ms); without it, the full hierarchy is loaded and serialized (p99: 10,000ms). This is the primary bulk sync endpoint used by consumers that need the entire taxonomy tree.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon services needing the full category hierarchy for a taxonomy (e.g., deal platform sync jobs, search indexers)
- **Frequency**: ~2,000 rpm (with `If-Modified-Since`), ~200 rpm (without header)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST API Resources | Receives and routes the flat hierarchy request | `continuumTaxonomyV2Service_restApi` |
| Request Filters & Authorization | Validates request authorization | `continuumTaxonomyV2Service_requestFilters` |
| Caching & Cache Builder | Checks modification timestamp or loads full hierarchy from Redis | `continuumTaxonomyV2Service_cachingCore` |
| Postgres Repositories | Provides full taxonomy data on cache miss | `continuumTaxonomyV2Service_postgresRepositories` |
| TaxonomyV2 Redis Cache | Stores taxonomy flat hierarchy and last-modified timestamps | `continuumTaxonomyV2Redis` |
| TaxonomyV2 Postgres DB | Authoritative fallback for full hierarchy data | `continuumTaxonomyV2Postgres` |

## Steps

1. **Receive HTTP request**: Consumer calls `GET /taxonomies/{guid}/flat` with an optional `If-Modified-Since` header and optional `fields` query parameter.
   - From: Consumer service
   - To: `continuumTaxonomyV2Service_restApi`
   - Protocol: REST (HTTP)

2. **Authorize request**: The Request Filter validates credentials.
   - From: `continuumTaxonomyV2Service_restApi`
   - To: `continuumTaxonomyV2Service_requestFilters`
   - Protocol: In-process call

3. **Check If-Modified-Since header (conditional path)**:
   - If the `If-Modified-Since` header is present AND the date is parseable, the Caching Core compares the header value against the taxonomy's cached last-updated timestamp in Redis.
   - If content has not changed since the provided timestamp: returns HTTP 304 Not Modified immediately (p99: 20ms)
   - If the date is not parseable: returns HTTP 406 with `{"message": "Unparseable date in if-modified-since header"}`
   - From: `continuumTaxonomyV2Service_restApi`
   - To: `continuumTaxonomyV2Service_cachingCore` → `continuumTaxonomyV2Redis`
   - Protocol: Redisson / Redis GET (timestamp key)

4. **Load flat hierarchy from cache**: If content has changed (or no `If-Modified-Since` was sent), the Caching Core loads the full flat hierarchy for the taxonomy from Redis.
   - From: `continuumTaxonomyV2Service_cachingCore`
   - To: `continuumTaxonomyV2Redis`
   - Protocol: Redisson bulk read

5. **Fallback to Postgres on cache miss**: If the flat hierarchy is not in Redis, the Caching Core falls back to Postgres Repositories to load all category nodes for the taxonomy.
   - From: `continuumTaxonomyV2Service_cachingCore`
   - To: `continuumTaxonomyV2Service_postgresRepositories` → `continuumTaxonomyV2Postgres`
   - Protocol: JDBI / JDBC SELECT (full taxonomy traversal)

6. **Return response**: The flat array of `CategoryFlatResponseEntity` objects is serialized to JSON and returned. Each entry contains: `guid`, `name`, `description`, `depth`, `parent`, `children`, `child_count`, `taxonomy_guid`, `attributes`, `locales`, `relationships`.
   - From: `continuumTaxonomyV2Service_restApi`
   - To: Consumer
   - Protocol: HTTP 200, `application/json;charset=UTF-8`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Taxonomy GUID not found | Returns 404 with `{"message": "Not Found!"}` | Caller receives 404 |
| Unparseable `If-Modified-Since` date | Returns 406 with error message | Caller must correct the date format |
| Redis unavailable | Falls back to Postgres; very high latency for full hierarchy | Request may succeed but extremely slowly; health alerts fire |
| Postgres unavailable | 500 returned | No fallback; full hierarchy cannot be served |

## Performance Notes

| Request Pattern | p99 Latency | p95 Latency | Throughput |
|-----------------|-------------|-------------|------------|
| With `If-Modified-Since` (unchanged) | 20ms | 10ms | ~2,000 rpm |
| Without `If-Modified-Since` (full load) | 10,000ms | 6,000ms | ~200 rpm |

Consumers must always send `If-Modified-Since` for production polling patterns to avoid triggering full hierarchy loads.

## Sequence Diagram

```
Consumer -> REST API: GET /taxonomies/{guid}/flat [If-Modified-Since: <date>] [fields: ...]
REST API -> Request Filters: validate authorization
alt Has valid If-Modified-Since header
  REST API -> Caching Core: check last_updated for taxonomy {guid}
  Caching Core -> Redis Cache: GET taxonomy_last_updated:{guid}
  alt Not modified since header date
    Redis Cache --> Caching Core: timestamp <= header date
    Caching Core --> REST API: not modified
    REST API -> Consumer: 304 Not Modified
  else Modified
    Redis Cache --> Caching Core: timestamp > header date
    Caching Core -> Redis Cache: GET taxonomy_flat:{guid}
    Redis Cache --> Caching Core: flat category array
    Caching Core --> REST API: category list
    REST API -> Consumer: 200 OK [{CategoryFlatResponseEntity}, ...]
  end
else No If-Modified-Since header
  REST API -> Caching Core: load full flat hierarchy for {guid}
  Caching Core -> Redis Cache: GET taxonomy_flat:{guid}
  alt Cache Hit
    Redis Cache --> Caching Core: full flat array
  else Cache Miss
    Caching Core -> Postgres Repositories: SELECT all categories for taxonomy {guid}
    Postgres Repositories -> Postgres DB: query
    Postgres DB --> Postgres Repositories: rows
    Postgres Repositories --> Caching Core: category list
  end
  Caching Core --> REST API: category list
  REST API -> Consumer: 200 OK [{CategoryFlatResponseEntity}, ...]
end
```

## Related

- Architecture dynamic view: `components-continuum-taxonomy-v2-service-components-view`
- Related flows: [Category Read (Cache-Aside)](category-read.md), [Snapshot Activation & Cache Invalidation](snapshot-activation.md)
