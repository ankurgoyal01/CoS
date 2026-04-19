---
service: "wishlist-service"
title: "Get Wishlist Lists"
generated: "2026-03-03"
type: flow
flow_name: "get-wishlist-lists"
flow_type: synchronous
trigger: "API GET request from GAPI or mobile app to retrieve a user's wishlist"
participants:
  - "wishlistApiResources"
  - "wishlistApplicationServices"
  - "wishlistPersistenceLayer"
  - "continuumWishlistPostgresRo"
  - "continuumWishlistRedisCluster"
  - "wishlistExternalClients"
  - "continuumDealCatalogService"
architecture_ref: "components-wishlist-service"
---

# Get Wishlist Lists

## Summary

This flow covers the synchronous path by which GAPI, the deal page, layout service, or a mobile app retrieves a user's wishlist lists and items. The service reads list and item metadata from the PostgreSQL read replica, optionally enriches item data with deal catalog information, and returns a paginated JSON response. This path must complete within the 40ms GAPI SLA.

## Trigger

- **Type**: api-call
- **Source**: GAPI (iTier wishlist front-end app, deal page, layout service), mobile iOS/Android app
- **Frequency**: On-demand, at high volume — up to ~20k RPS at peak (parallel per-user requests from GAPI deal decoration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GAPI / mobile caller | Sends GET request with consumerId and optional filters | External |
| API Resources | Receives and parses GET request; extracts query parameters | `wishlistApiResources` |
| Application Services | Orchestrates list/item retrieval and optional enrichment | `wishlistApplicationServices` |
| Persistence Layer | Queries PostgreSQL read replica for list and item records | `wishlistPersistenceLayer` |
| Wishlist Postgres RO | Serves list and item data read queries | `continuumWishlistPostgresRo` |
| Wishlist Redis Cluster | Serves cached deal metadata on cache hit | `continuumWishlistRedisCluster` |
| External Service Clients | Fetches deal metadata from Deal Catalog on cache miss | `wishlistExternalClients` |
| Deal Catalog Service | Returns deal metadata and creative data | `continuumDealCatalogService` |

## Steps

1. **Receive read request**: GAPI sends `GET /wishlists/v1/lists?consumerId=<uuid>` (all lists) or `GET /wishlists/v1/lists/{listId}?consumerId=<uuid>` (specific list) or `GET /wishlists/v1/lists/query?consumerId=<uuid>&listName=<name>`.
   - From: GAPI / mobile app
   - To: `wishlistApiResources`
   - Protocol: REST (HTTP)

2. **Parse request**: API Resources extracts `consumerId`, optional `listId`/`listName`, `offset`, `limit`, `sort`, `containsDeal`, `containsOption`, `channel`, `purchased`, `gifted`, `locale`, `bcookie`, `clientId`.
   - From: `wishlistApiResources`
   - To: `wishlistApplicationServices`
   - Protocol: direct

3. **Query PostgreSQL read replica**: Application Services instructs Persistence Layer to fetch lists and items matching the request criteria.
   - From: `wishlistApplicationServices`
   - To: `wishlistPersistenceLayer` → `continuumWishlistPostgresRo`
   - Protocol: JDBC

4. **Apply filters and sort**: Application Services applies any in-memory sorting and filtering specified by the `sort` parameter via `SortParser`.
   - From: `wishlistApplicationServices`
   - To: `wishlistApplicationServices` (in-process)
   - Protocol: direct

5. **Enrich with deal metadata (if `enableClientCache` is true)**: For each item's `dealId`, Application Services checks the Redis cache for deal metadata. On cache hit, metadata is returned immediately. On cache miss, External Service Clients fetch from Deal Catalog Service.
   - From: `wishlistApplicationServices` → `wishlistExternalClients`
   - To: `continuumWishlistRedisCluster` (cache hit) or `continuumDealCatalogService` (cache miss)
   - Protocol: Redis / HTTP

6. **Assemble paginated response**: Application Services constructs a `GetListResponse` (for single-list queries) or `GetAllListsResponse` (for multi-list queries) with `ItemList` data and `Pagination` metadata (`count`, `offset`, `total`).
   - From: `wishlistApplicationServices`
   - To: `wishlistApiResources`
   - Protocol: direct

7. **Return response**: API Resources serializes the response to JSON and returns HTTP 200.
   - From: `wishlistApiResources`
   - To: GAPI / mobile app
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `consumerId` | Validation in API Resources | HTTP 400 Bad Request |
| PostgreSQL replica unavailable | Exception propagated; logged | HTTP 500; GAPI ignores response |
| Deal Catalog cache miss + upstream timeout | Retry or degraded response without deal metadata | Partial list response returned |
| Response exceeds 40ms | GAPI ignores response upstream | User sees no wishlist indicator |

## Sequence Diagram

```
Caller -> wishlistApiResources: GET /wishlists/v1/lists?consumerId=<uuid>&offset=0&limit=100
wishlistApiResources -> wishlistApplicationServices: getLists(consumerId, filters, pagination)
wishlistApplicationServices -> wishlistPersistenceLayer: fetchLists(consumerId, filters)
wishlistPersistenceLayer -> continuumWishlistPostgresRo: SELECT lists, items WHERE consumerId=...
continuumWishlistPostgresRo --> wishlistPersistenceLayer: list + item records
wishlistPersistenceLayer --> wishlistApplicationServices: List<ItemList>
wishlistApplicationServices -> continuumWishlistRedisCluster: GET deal metadata (cache hit?)
continuumWishlistRedisCluster --> wishlistApplicationServices: cached metadata (or MISS)
wishlistApplicationServices -> wishlistExternalClients: fetchDealMetadata(dealId) [on cache miss]
wishlistExternalClients -> continuumDealCatalogService: GET /deal/{dealId}?clientId=edc279c643e5b7bb-Wishlist
continuumDealCatalogService --> wishlistExternalClients: deal metadata JSON
wishlistExternalClients --> wishlistApplicationServices: DealMetadata
wishlistApplicationServices -> continuumWishlistRedisCluster: SET deal metadata (populate cache)
wishlistApplicationServices --> wishlistApiResources: GetAllListsResponse
wishlistApiResources --> Caller: HTTP 200 { data: [...], pagination: {...} }
```

## Related

- Architecture component view: `components-wishlist-service`
- Related flows: [Add Wishlist Item](add-wishlist-item.md)
