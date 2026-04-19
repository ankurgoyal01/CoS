---
service: "travel-search"
title: "Hotel Search Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "hotel-search-flow"
flow_type: synchronous
trigger: "REST API call from Getaways client application"
participants:
  - "externalGetawaysClients_2f4a"
  - "travelSearch_apiResources"
  - "searchManager"
  - "hotelDetailsManager"
  - "travelSearch_cacheLayer"
  - "travelSearch_persistenceLayer"
  - "travelSearch_externalClients"
  - "externalGeoService_4c0d"
  - "externalInventoryService_5d2a"
  - "continuumDealCatalogService"
  - "externalRelevanceService_c3d4"
  - "externalGapFilteringService_d4e5"
architecture_ref: "dynamic-hotelSearchFlow"
---

# Hotel Search Flow

## Summary

This is the primary synchronous flow for hotel search. A Getaways client application sends a search request (by destination, dates, and filters) to the REST API. The `searchManager` fans out to geo resolution, deal catalog, availability, relevance ranking, and gap-filtering services to assemble a ranked and filtered result set, which is returned to the caller. This flow is the architectural dynamic view `dynamic-hotelSearchFlow`.

## Trigger

- **Type**: api-call
- **Source**: Getaways client application (`externalGetawaysClients_2f4a`) — `GET /travel-search/v1/search`
- **Frequency**: On-demand (per user search interaction)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Getaways Clients | Initiates search request | `externalGetawaysClients_2f4a` |
| REST Resources | Receives HTTP request; routes to search orchestration | `travelSearch_apiResources` |
| Search Orchestration | Coordinates fan-out to downstream services; aggregates results | `searchManager` |
| Hotel Details Manager | Performs hotel-level detail lookups for result enrichment | `hotelDetailsManager` |
| Cache Layer | Serves cached hotel data for matched hotels | `travelSearch_cacheLayer` |
| Persistence Layer | Provides DB fallback and stored configuration | `travelSearch_persistenceLayer` |
| External Service Clients | Issues outbound calls to geo, inventory, deal, relevance, and gap-filtering services | `travelSearch_externalClients` |
| Geo Service | Resolves destination to a geo-scoped hotel list | `externalGeoService_4c0d` |
| Inventory Service | Returns availability summaries for the date range | `externalInventoryService_5d2a` |
| Deal Catalog Service | Returns deal catalog data for Getaways offers | `continuumDealCatalogService` |
| Relevance Service | Returns relevance-ranked ordering for the result set | `externalRelevanceService_c3d4` |
| Gap-Filtering Service | Applies locale-specific gap filtering to the final results | `externalGapFilteringService_d4e5` |

## Steps

1. **Receives search request**: Getaways client submits a hotel search with destination, check-in/check-out dates, and optional filters.
   - From: `externalGetawaysClients_2f4a`
   - To: `travelSearch_apiResources`
   - Protocol: REST (HTTP GET)

2. **Routes to search orchestration**: REST resource validates the request and invokes the search flow.
   - From: `travelSearch_apiResources`
   - To: `searchManager`
   - Protocol: direct

3. **Reads stored configuration**: Search orchestration reads any service-level search configuration (e.g., ranking weights, enabled features).
   - From: `searchManager`
   - To: `travelSearch_persistenceLayer`
   - Protocol: direct (Ebean / MySQL)

4. **Resolves destination to geo hotel list**: Calls the Geo Service to translate the destination string into a geographic scope and returns the candidate hotel set.
   - From: `travelSearch_externalClients`
   - To: `externalGeoService_4c0d`
   - Protocol: REST

5. **Fetches deal catalog data**: Retrieves Getaways deal catalog entries matching the candidate hotels.
   - From: `travelSearch_externalClients`
   - To: `continuumDealCatalogService`
   - Protocol: REST

6. **Fetches availability summaries**: Queries Inventory Service for availability status across the candidate hotels for the requested date range.
   - From: `travelSearch_externalClients`
   - To: `externalInventoryService_5d2a`
   - Protocol: REST

7. **Requests hotel details for result set**: For hotels in the candidate set, invokes Hotel Details Manager to enrich results with content and cached data.
   - From: `searchManager`
   - To: `hotelDetailsManager`
   - Protocol: direct

8. **Reads cached hotel data**: Hotel Details Manager reads each hotel's cached data from Redis.
   - From: `hotelDetailsManager`
   - To: `travelSearch_cacheLayer`
   - Protocol: direct (Redis)

9. **Falls back to persistent data on cache miss**: If Redis does not have a cached record, the cache layer reads from MySQL.
   - From: `travelSearch_cacheLayer`
   - To: `travelSearch_persistenceLayer`
   - Protocol: direct (Ebean / MySQL)

10. **Applies relevance ranking**: Passes assembled results to the Relevance Service to obtain a ranked ordering.
    - From: `travelSearch_externalClients`
    - To: `externalRelevanceService_c3d4`
    - Protocol: REST

11. **Applies gap filtering**: Passes ranked results to the Gap-Filtering Service to remove locale-inappropriate offers.
    - From: `travelSearch_externalClients`
    - To: `externalGapFilteringService_d4e5`
    - Protocol: REST

12. **Builds and returns search response**: Search Orchestration assembles the final result set and returns it to the REST resource layer.
    - From: `searchManager`
    - To: `travelSearch_apiResources`
    - Protocol: direct

13. **Returns response to client**: REST resource serialises the result and sends the HTTP response.
    - From: `travelSearch_apiResources`
    - To: `externalGetawaysClients_2f4a`
    - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Geo Service unavailable | Fail-fast or empty candidate list | Search returns empty results or error response |
| Inventory Service unavailable | Degrade gracefully; omit availability data | Results returned without availability status |
| Deal Catalog unavailable | Degrade gracefully; omit deal data | Results returned without deal enrichment |
| Relevance Service unavailable | Degrade to default ordering | Results returned in unranked order |
| Gap-Filtering Service unavailable | Degrade gracefully; skip filtering | Results returned unfiltered (may include locale gaps) |
| Redis cache unavailable | Fall back to MySQL via persistence layer | Increased latency; MySQL absorbs read load |

## Sequence Diagram

```
GetawaysClients    -> travelSearch_apiResources  : GET /travel-search/v1/search
travelSearch_apiResources -> searchManager       : Search request
searchManager      -> travelSearch_persistenceLayer : Read configuration
searchManager      -> travelSearch_externalClients  : Geo, deal, availability lookups
travelSearch_externalClients -> externalGeoService_4c0d       : Resolve destination
travelSearch_externalClients -> continuumDealCatalogService   : Fetch deals
travelSearch_externalClients -> externalInventoryService_5d2a : Fetch availability
searchManager      -> hotelDetailsManager        : Hotel lookup
hotelDetailsManager -> travelSearch_cacheLayer   : Read cache
travelSearch_cacheLayer -> travelSearch_persistenceLayer : Fallback to DB
travelSearch_externalClients -> externalRelevanceService_c3d4  : Relevance ranking
travelSearch_externalClients -> externalGapFilteringService_d4e5 : Gap filtering
searchManager      -> travelSearch_apiResources  : Search response
travelSearch_apiResources --> GetawaysClients    : HTTP 200 search results
```

## Related

- Architecture dynamic view: `dynamic-hotelSearchFlow`
- Related flows: [Hotel Detail Retrieval Flow](hotel-detail-retrieval.md), [EAN Price Update Flow](ean-price-update.md)
