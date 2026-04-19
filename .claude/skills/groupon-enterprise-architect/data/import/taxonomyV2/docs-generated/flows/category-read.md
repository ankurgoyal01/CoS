---
service: "taxonomyV2"
title: "Category Read (Cache-Aside)"
generated: "2026-03-03"
type: flow
flow_name: "category-read"
flow_type: synchronous
trigger: "GET /categories/{guid} API call from a consumer service"
participants:
  - "continuumTaxonomyV2Service_restApi"
  - "continuumTaxonomyV2Service_requestFilters"
  - "continuumTaxonomyV2Service_cachingCore"
  - "continuumTaxonomyV2Service_postgresRepositories"
  - "continuumTaxonomyV2Redis"
  - "continuumTaxonomyV2Postgres"
architecture_ref: "components-continuum-taxonomy-v2-service-components-view"
---

# Category Read (Cache-Aside)

## Summary

This is the highest-throughput read path in Taxonomy V2, handling ~42,000 rpm at p99 latency of 20ms. When a consumer service requests category details by UUID, the request passes through authorization filters and is routed to the Caching Core, which first attempts to resolve the category from the Redis cache. On a cache hit, the denormalized category object (name, description, depth, parent, children, attributes, locales, relationships) is returned immediately. On a cache miss, the Caching Core falls back to Postgres and may prime the cache entry for future requests.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon services (deal platform, merchant platform, search, browse) calling `GET /categories/{guid}`
- **Frequency**: ~42,000 rpm in production

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST API Resources | Receives HTTP request and routes to appropriate service | `continuumTaxonomyV2Service_restApi` |
| Request Filters & Authorization | Validates authorization on incoming request | `continuumTaxonomyV2Service_requestFilters` |
| Caching & Cache Builder | Resolves category from Redis cache or Postgres fallback | `continuumTaxonomyV2Service_cachingCore` |
| Postgres Repositories | Fetches category data from Postgres on cache miss | `continuumTaxonomyV2Service_postgresRepositories` |
| TaxonomyV2 Redis Cache | Primary read target — denormalized category data | `continuumTaxonomyV2Redis` |
| TaxonomyV2 Postgres DB | Fallback read target — authoritative category data | `continuumTaxonomyV2Postgres` |

## Steps

1. **Receive HTTP request**: Consumer calls `GET /categories/{guid}` with an optional `all_fields=true` query parameter.
   - From: Consumer service
   - To: `continuumTaxonomyV2Service_restApi`
   - Protocol: REST (HTTP)

2. **Authorize request**: The `continuumTaxonomyV2Service_requestFilters` validates the caller's credentials against user/role data managed by `continuumTaxonomyV2Service_userManagement`.
   - From: `continuumTaxonomyV2Service_restApi`
   - To: `continuumTaxonomyV2Service_requestFilters`
   - Protocol: In-process call

3. **Attempt Redis cache read**: The REST API invokes the Caching Core to look up the category by its UUID in Redis.
   - From: `continuumTaxonomyV2Service_restApi`
   - To: `continuumTaxonomyV2Service_cachingCore` → `continuumTaxonomyV2Redis`
   - Protocol: Redisson / Redis GET

4a. **Cache hit — return response**: If the category is found in Redis, the denormalized object is deserialized and returned.
   - From: `continuumTaxonomyV2Redis`
   - To: `continuumTaxonomyV2Service_cachingCore` → `continuumTaxonomyV2Service_restApi` → Caller
   - Protocol: In-process → REST HTTP 200

4b. **Cache miss — fallback to Postgres**: If the category is not found in Redis (e.g., after a cache flush or before first cache build), the Caching Core falls back to Postgres Repositories.
   - From: `continuumTaxonomyV2Service_cachingCore`
   - To: `continuumTaxonomyV2Service_postgresRepositories` → `continuumTaxonomyV2Postgres`
   - Protocol: JDBI / JDBC SELECT

5. **Return category response**: The resolved category object (with name, description, depth, parent GUID, children GUIDs, attributes, locales, relationships) is serialized to JSON and returned.
   - From: `continuumTaxonomyV2Service_restApi`
   - To: Caller
   - Protocol: HTTP 200, `application/json;charset=UTF-8`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Category GUID not found in Redis or Postgres | Returns 404 with `{"message": "Not Found!"}` | Caller receives 404 |
| Redis unavailable | Falls back to Postgres; elevated latency | Request succeeds with higher latency; alerts triggered on Redis health check failure |
| Postgres unavailable | No fallback — request fails | 500 returned to caller; health check alarm |
| Authorization failure | Request rejected by filter | 401/403 returned |

## Sequence Diagram

```
Consumer -> REST API: GET /categories/{guid}?all_fields=false
REST API -> Request Filters: validate authorization
Request Filters -> REST API: authorized
REST API -> Caching Core: lookup category by GUID
Caching Core -> Redis Cache: GET category:{guid}
alt Cache Hit
  Redis Cache --> Caching Core: category data
  Caching Core --> REST API: category object
else Cache Miss
  Redis Cache --> Caching Core: nil
  Caching Core -> Postgres Repositories: SELECT category WHERE guid={guid}
  Postgres Repositories -> Postgres DB: query
  Postgres DB --> Postgres Repositories: row data
  Postgres Repositories --> Caching Core: category object
  Caching Core --> REST API: category object
end
REST API -> Consumer: 200 OK {guid, name, description, depth, parent, children, attributes, locales, relationships}
```

## Related

- Architecture dynamic view: `components-continuum-taxonomy-v2-service-components-view`
- Related flows: [Flat Taxonomy Hierarchy Query](flat-taxonomy-query.md), [Snapshot Activation & Cache Invalidation](snapshot-activation.md)
