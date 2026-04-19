---
service: "Deal-Estate"
title: "Deal Search and List"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-search-and-list"
flow_type: synchronous
trigger: "API call — GET /deals or GET /deals/search"
participants:
  - "continuumDealEstateWeb"
  - "continuumDealEstateMysql"
  - "continuumDealEstateMemcached"
  - "continuumDealEstateRedis"
  - "continuumTaxonomyService"
  - "continuumGeoPlacesService"
architecture_ref: "dynamic-deal-search-and-list"
---

# Deal Search and List

## Summary

This flow handles retrieval and filtering of deal records for internal tooling and Continuum services. The web layer accepts query parameters (state, merchant, date range, taxonomy, geography, etc.), queries MySQL for matching records, optionally enriches results from Memcached cache, and returns a structured deal list. For taxonomy- or geo-filtered searches, ancillary lookups are made to the Taxonomy and Geo Places services.

## Trigger

- **Type**: api-call
- **Source**: Internal tooling or Continuum services calling `GET /deals` (list) or `GET /deals/search` (filtered search)
- **Frequency**: On-demand (per request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Estate Web | Receives search request, builds query, returns results | `continuumDealEstateWeb` |
| Deal Estate MySQL | Primary source of deal records for search queries | `continuumDealEstateMysql` |
| Deal Estate Memcached | Caches frequent or expensive query results | `continuumDealEstateMemcached` |
| Deal Estate Redis | Holds feature flags controlling search behaviour (rollout) | `continuumDealEstateRedis` |
| Taxonomy Service | Resolves taxonomy filter values for category-based search | `continuumTaxonomyService` |
| Geo Places Service | Resolves geo filter values for location-based search | `continuumGeoPlacesService` |

## Steps

1. **Receive search or list request**: Caller submits `GET /deals` or `GET /deals/search` with optional filter parameters (state, merchant ID, date range, taxonomy ID, geo filter, etc.).
   - From: `caller`
   - To: `continuumDealEstateWeb`
   - Protocol: REST

2. **Check feature flags**: Reads rollout flags from Redis to determine whether any search feature variants are active.
   - From: `continuumDealEstateWeb`
   - To: `continuumDealEstateRedis`
   - Protocol: Redis protocol

3. **Resolve taxonomy filters (if applicable)**: If a taxonomy filter is provided, fetches taxonomy data from Taxonomy Service to translate category identifiers.
   - From: `continuumDealEstateWeb`
   - To: `continuumTaxonomyService`
   - Protocol: REST (service-client)

4. **Resolve geo filters (if applicable)**: If a location filter is provided, fetches geo place data from Geo Places Service to resolve region or area identifiers.
   - From: `continuumDealEstateWeb`
   - To: `continuumGeoPlacesService`
   - Protocol: REST (service-client)

5. **Check Memcached for cached results**: Checks whether the resolved query has a cached result in Memcached.
   - From: `continuumDealEstateWeb`
   - To: `continuumDealEstateMemcached`
   - Protocol: Memcached protocol

6. **Query MySQL (on cache miss)**: Executes the filtered ActiveRecord query against MySQL to retrieve matching deal records.
   - From: `continuumDealEstateWeb`
   - To: `continuumDealEstateMysql`
   - Protocol: ActiveRecord / SQL

7. **Cache results**: Writes the query results to Memcached for subsequent requests with the same parameters.
   - From: `continuumDealEstateWeb`
   - To: `continuumDealEstateMemcached`
   - Protocol: Memcached protocol

8. **Return deal list to caller**: Returns paginated deal list as JSON response.
   - From: `continuumDealEstateWeb`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid filter parameters | Rails validation returns error | HTTP 422; no query executed |
| MySQL unavailable | ActiveRecord exception | HTTP 500; no results returned |
| Taxonomy Service unavailable | service-client error; taxonomy filter skipped or error returned | HTTP 502 or degraded results without taxonomy enrichment |
| Geo Places Service unavailable | service-client error; geo filter skipped or error returned | HTTP 502 or degraded results without geo enrichment |
| Memcached unavailable | Cache miss; falls through to MySQL | Results returned without caching; higher MySQL load |

## Sequence Diagram

```
caller -> continuumDealEstateWeb: GET /deals/search?filters=...
continuumDealEstateWeb -> continuumDealEstateRedis: read feature flags (rollout)
continuumDealEstateWeb -> continuumTaxonomyService: resolve taxonomy filters (if applicable)
continuumDealEstateWeb -> continuumGeoPlacesService: resolve geo filters (if applicable)
continuumDealEstateWeb -> continuumDealEstateMemcached: check cache (cache key from resolved filters)
continuumDealEstateMemcached --> continuumDealEstateWeb: cache miss
continuumDealEstateWeb -> continuumDealEstateMysql: SELECT deals WHERE filters
continuumDealEstateWeb -> continuumDealEstateMemcached: SET cached results
continuumDealEstateWeb --> caller: 200 OK / deal list JSON
```

## Related

- Architecture dynamic view: `dynamic-deal-search-and-list`
- Related flows: [Deal Creation and Import](deal-creation-and-import.md)
