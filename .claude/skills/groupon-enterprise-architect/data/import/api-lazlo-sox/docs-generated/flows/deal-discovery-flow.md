---
service: "api-lazlo-sox"
title: "Deal Discovery Flow"
generated: "2026-03-03"
type: flow
flow_name: "deal-discovery-flow"
flow_type: synchronous
trigger: "User browses deals, searches, or views a deal listing"
participants:
  - "continuumApiLazloService_httpApi"
  - "continuumApiLazloService_commonFiltersAndViews"
  - "continuumApiLazloService_dealsAndListingsApi"
  - "continuumApiLazloService_geoAndTaxonomyApi"
  - "continuumApiLazloService_dealsBlsModule"
  - "continuumApiLazloService_downstreamServiceClients"
  - "continuumApiLazloService_redisAccess"
  - "continuumApiLazloRedisCache"
architecture_ref: "dynamic-api-lazlo-deal-discovery"
---

# Deal Discovery Flow

## Summary

This flow describes how API Lazlo handles deal discovery and browsing -- the core Groupon experience where users browse, search, and view deals. The Deals and Listings API receives requests for deal feeds, individual deal pages, card search results, and listing data. The Deals BLS module orchestrates calls to downstream deal, catalog, inventory, geo, relevance, and content services, composing a rich mobile-optimized deal experience. Taxonomy and geo data are heavily cached in Redis to minimize downstream calls.

## Trigger

- **Type**: User action
- **Source**: User opens the Groupon app, browses categories, searches for deals, or taps a deal card
- **Frequency**: Per-request (highest volume endpoint group in API Lazlo)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Mobile Client | Initiates deal browsing or search | External |
| HTTP Mobile API Gateway | Receives and routes the deal request | `continuumApiLazloService_httpApi` |
| Common Filters, Params and Views | Applies locale, geo context, and header processing | `continuumApiLazloService_commonFiltersAndViews` |
| Deals and Listings API | Handles /deals, /listings, /cardsearch endpoints | `continuumApiLazloService_dealsAndListingsApi` |
| Geo, Divisions and Taxonomy API | Handles /taxonomies, /divisions for geo-aware browsing | `continuumApiLazloService_geoAndTaxonomyApi` |
| Deals and Catalog BLS Module | Orchestrates deal discovery across multiple downstream services | `continuumApiLazloService_dealsBlsModule` |
| Downstream Service Clients | Calls Deal, Catalog, Inventory, Geo, Relevance, Content services | `continuumApiLazloService_downstreamServiceClients` |
| Redis Cache Access | Caches taxonomy, geo, and deal-related computations | `continuumApiLazloService_redisAccess` |
| API Lazlo Redis Cache | Distributed cache for taxonomy and deal data | `continuumApiLazloRedisCache` |

## Steps

1. **Client requests deals**: Mobile client sends a GET request (e.g., `/api/mobile/{countryCode}/deals?category={cat}&lat={lat}&lng={lng}`).
   - From: Mobile Client
   - To: `continuumApiLazloService_httpApi`
   - Protocol: HTTPS/JSON

2. **Apply common filters**: Locale resolution, geo context extraction, header processing, and metrics initialization.
   - From: `continuumApiLazloService_httpApi`
   - To: `continuumApiLazloService_commonFiltersAndViews`
   - Protocol: in-process

3. **Route to Deals controller**: The HTTP gateway routes the request to the Deals and Listings API controller.
   - From: `continuumApiLazloService_httpApi`
   - To: `continuumApiLazloService_dealsAndListingsApi`
   - Protocol: in-process

4. **Delegate to Deals BLS**: The Deals controller delegates to the Deals and Catalog BLS Module for orchestration.
   - From: `continuumApiLazloService_dealsAndListingsApi`
   - To: `continuumApiLazloService_dealsBlsModule`
   - Protocol: Lazlo EventBus / Promises

5. **Resolve taxonomy from cache**: The BLS module resolves the requested category taxonomy from Redis cache. Taxonomy data is pre-cached and has longer TTLs.
   - From: `continuumApiLazloService_dealsBlsModule`
   - To: `continuumApiLazloService_redisAccess`
   - Protocol: Redis client

6. **Call Deal Service**: The BLS module calls the Deal Service for deal data matching the requested category, location, and filters.
   - From: `continuumApiLazloService_dealsBlsModule`
   - To: `continuumApiLazloService_downstreamServiceClients` (Deal client)
   - Protocol: HTTP/JSON over internal network

7. **Call Relevance Service**: For personalized recommendations and ranking, the BLS module calls the Relevance Service with user context.
   - From: `continuumApiLazloService_dealsBlsModule`
   - To: `continuumApiLazloService_downstreamServiceClients` (Relevance client)
   - Protocol: HTTP/JSON over internal network

8. **Call Inventory Service**: The BLS module checks inventory availability for the returned deals.
   - From: `continuumApiLazloService_dealsBlsModule`
   - To: `continuumApiLazloService_downstreamServiceClients` (Inventory client)
   - Protocol: HTTP/JSON over internal network

9. **Call Content Service**: Additional editorial content and images are fetched from the Content Service.
   - From: `continuumApiLazloService_dealsBlsModule`
   - To: `continuumApiLazloService_downstreamServiceClients` (Content client)
   - Protocol: HTTP/JSON over internal network

10. **Compose deal feed**: The BLS module merges deal data, relevance scores, inventory status, and content into a mobile-optimized deal feed response.
    - From: `continuumApiLazloService_dealsBlsModule`
    - To: Internal composition

11. **Cache computed results**: Computed deal compositions and taxonomy resolutions are cached in Redis.
    - From: `continuumApiLazloService_dealsBlsModule`
    - To: `continuumApiLazloService_redisAccess`
    - Protocol: Redis client

12. **Return deal feed response**: The composed deal feed JSON is returned through the controller and HTTP gateway to the mobile client.
    - From: `continuumApiLazloService_httpApi`
    - To: Mobile Client
    - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Service unavailable | Timeout from downstream client | 502 Bad Gateway; deal feed cannot be served |
| Relevance Service unavailable | Fallback to non-personalized ordering | Deals returned without personalization (degraded) |
| Inventory Service unavailable | Deals returned without real-time inventory status | Degraded: user may see sold-out deals |
| Taxonomy cache miss | Synchronous call to Taxonomy Service to repopulate | Slightly higher latency on first request |
| Invalid category/location | Controller validates parameters | 400 Bad Request with validation errors |
| No deals found | Empty result set returned | 200 OK with empty deals array |

## Sequence Diagram

```
Mobile Client -> continuumApiLazloService_httpApi: GET /api/mobile/{cc}/deals?category=...&lat=...&lng=...
continuumApiLazloService_httpApi -> continuumApiLazloService_commonFiltersAndViews: Apply filters (locale, geo, headers)
continuumApiLazloService_commonFiltersAndViews --> continuumApiLazloService_httpApi: Filters applied
continuumApiLazloService_httpApi -> continuumApiLazloService_dealsAndListingsApi: Route to Deals controller
continuumApiLazloService_dealsAndListingsApi -> continuumApiLazloService_dealsBlsModule: Delegate via EventBus
continuumApiLazloService_dealsBlsModule -> continuumApiLazloService_redisAccess: Resolve taxonomy (cache)
continuumApiLazloService_redisAccess -> continuumApiLazloRedisCache: GET taxonomy:{category}
continuumApiLazloRedisCache --> continuumApiLazloService_redisAccess: Taxonomy data
continuumApiLazloService_dealsBlsModule -> continuumApiLazloService_downstreamServiceClients: Call Deal Service
continuumApiLazloService_downstreamServiceClients --> continuumApiLazloService_dealsBlsModule: Deal data
continuumApiLazloService_dealsBlsModule -> continuumApiLazloService_downstreamServiceClients: Call Relevance Service
continuumApiLazloService_downstreamServiceClients --> continuumApiLazloService_dealsBlsModule: Relevance scores
continuumApiLazloService_dealsBlsModule -> continuumApiLazloService_downstreamServiceClients: Call Inventory Service
continuumApiLazloService_downstreamServiceClients --> continuumApiLazloService_dealsBlsModule: Inventory status
continuumApiLazloService_dealsBlsModule -> continuumApiLazloService_downstreamServiceClients: Call Content Service
continuumApiLazloService_downstreamServiceClients --> continuumApiLazloService_dealsBlsModule: Content data
continuumApiLazloService_dealsBlsModule -> continuumApiLazloService_redisAccess: Cache composed results
continuumApiLazloService_dealsBlsModule --> continuumApiLazloService_dealsAndListingsApi: Composed deal feed
continuumApiLazloService_dealsAndListingsApi --> continuumApiLazloService_httpApi: Controller response
continuumApiLazloService_httpApi --> Mobile Client: HTTPS JSON deal feed
```

## Related

- Architecture component view: `components-continuum-continuumApiLazloService_httpApi-lazlo-service`
- Related flows: [Mobile API Request Flow](mobile-api-request-flow.md), [User Authentication Flow](user-authentication-flow.md)
