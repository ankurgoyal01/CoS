---
service: "darwin-groupon-deals"
title: "REST Deal Search"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "rest-deal-search"
flow_type: synchronous
trigger: "Inbound HTTP GET request to /v2/deals/search, /cards/v1/search, /batch/cards/v1/search, or /v1/deals/local"
participants:
  - "apiResource"
  - "cacheLayer"
  - "aggregationEngine"
  - "externalClients"
  - "modelStore"
  - "continuumDarwinAggregatorService"
  - "elasticsearchClusterExt_b8f21c"
  - "redisClusterExt_9d0c11"
  - "continuumDealCatalogService"
  - "continuumBadgesService"
  - "continuumUserIdentitiesService"
  - "continuumGeoPlacesService"
  - "continuumGeoDetailsService"
  - "cardatronServiceExt_bf5c13"
  - "audienceUserAttributesServiceExt_6e01f4"
  - "citrusAdsServiceExt_19e7ad"
  - "spellCorrectionServiceExt_7a0f02"
architecture_ref: "darwinAggregatorServiceComponents"
---

# REST Deal Search

## Summary

The REST Deal Search flow is the primary synchronous path for consumer deal discovery. A caller submits an HTTP GET request specifying a search query, geo context, and user identity; the service applies spell correction, checks the Redis cache, fans out to a wide set of upstream services, applies ML-powered relevance ranking with personalization signals, blends in sponsored ads, and returns a ranked list of deal cards. The flow is designed to degrade gracefully when individual upstream dependencies are unavailable.

## Trigger

- **Type**: api-call
- **Source**: Downstream consumer (mobile app, web frontend, or internal service) via HTTP GET
- **Frequency**: per-request (on-demand, high frequency in production)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `apiResource` | Receives and validates inbound HTTP request; routes to aggregation pipeline | `continuumDarwinAggregatorService` |
| `cacheLayer` | Checks Redis for a cached response before executing aggregation | `continuumDarwinAggregatorService` |
| `aggregationEngine` | Orchestrates fan-out, collects results, invokes ranking | `continuumDarwinAggregatorService` |
| `externalClients` | Executes HTTP calls to all upstream services in parallel | `continuumDarwinAggregatorService` |
| `modelStore` | Supplies current ML model artifacts to the ranking step | `continuumDarwinAggregatorService` |
| Elasticsearch Cluster | Returns candidate deals matching query and filters | `elasticsearchClusterExt_b8f21c` |
| Redis Cluster | Returns cached response (on hit) or stores new response (on miss) | `redisClusterExt_9d0c11` |
| Deal Catalog Service | Supplies full deal details for result enrichment | `continuumDealCatalogService` |
| Badges Service | Supplies badge metadata for each deal | `continuumBadgesService` |
| User Identities Service | Resolves user identity for personalization | `continuumUserIdentitiesService` |
| Geo Places Service | Resolves geo place context for location filtering | `continuumGeoPlacesService` |
| Geo Details Service | Supplies geo detail enrichment | `continuumGeoDetailsService` |
| Cardatron Service | Supplies card layout and deck data | `cardatronServiceExt_bf5c13` |
| Audience User Attributes | Supplies audience segmentation attributes | `audienceUserAttributesServiceExt_6e01f4` |
| Citrus Ads | Supplies sponsored ad placements to blend | `citrusAdsServiceExt_19e7ad` |
| Spell Correction Service | Corrects misspelled search terms | `spellCorrectionServiceExt_7a0f02` |

## Steps

1. **Receive Request**: `apiResource` receives and validates the inbound HTTP GET request.
   - From: `Consumer (mobile app / web frontend)`
   - To: `apiResource`
   - Protocol: REST/HTTP

2. **Spell Correction**: `externalClients` queries Spell Correction Service to normalize search query terms.
   - From: `aggregationEngine`
   - To: `spellCorrectionServiceExt_7a0f02`
   - Protocol: REST/HTTP

3. **Cache Lookup**: `cacheLayer` checks Redis for a previously cached response matching the request key.
   - From: `cacheLayer`
   - To: `redisClusterExt_9d0c11`
   - Protocol: Redis protocol

4. **Cache Hit — Return Early**: If a cached response is found, `cacheLayer` deserializes (Kryo) and returns it directly to the caller. Flow ends here.
   - From: `cacheLayer`
   - To: `apiResource` -> consumer
   - Protocol: In-process / REST/HTTP

5. **Cache Miss — Resolve User Identity**: `externalClients` calls User Identities Service to resolve the requesting user.
   - From: `aggregationEngine`
   - To: `continuumUserIdentitiesService`
   - Protocol: REST/HTTP

6. **Resolve Geo Context**: `externalClients` calls Geo Places and Geo Details Services in parallel to resolve location context.
   - From: `aggregationEngine`
   - To: `continuumGeoPlacesService`, `continuumGeoDetailsService`
   - Protocol: REST/HTTP

7. **Query Elasticsearch**: `externalClients` executes a deal index query against Elasticsearch using the corrected query, geo context, and filters.
   - From: `aggregationEngine`
   - To: `elasticsearchClusterExt_b8f21c`
   - Protocol: Elasticsearch HTTP

8. **Enrich with Deal Catalog**: `externalClients` fetches full deal details for Elasticsearch result candidates from Deal Catalog Service.
   - From: `aggregationEngine`
   - To: `continuumDealCatalogService`
   - Protocol: REST/HTTP

9. **Fetch Badges**: `externalClients` retrieves badge metadata for each deal candidate.
   - From: `aggregationEngine`
   - To: `continuumBadgesService`
   - Protocol: REST/HTTP

10. **Fetch Audience Attributes**: `externalClients` retrieves audience segmentation attributes for the resolved user.
    - From: `aggregationEngine`
    - To: `audienceUserAttributesServiceExt_6e01f4`
    - Protocol: REST/HTTP

11. **Fetch Card and Deck Data**: `externalClients` retrieves card layout and deck configuration from Cardatron and Alligator Deck Config.
    - From: `aggregationEngine`
    - To: `cardatronServiceExt_bf5c13`, `alligatorDeckConfigServiceExt_8c4d21`
    - Protocol: REST/HTTP

12. **Load ML Model**: `modelStore` provides current ML ranking model artifacts to `aggregationEngine`.
    - From: `aggregationEngine`
    - To: `modelStore` (in-process, backed by `watsonObjectStorageExt_3a1f2c`)
    - Protocol: In-process / Object Storage SDK

13. **Rank and Personalize**: `aggregationEngine` scores and ranks deal candidates using ML model, user identity, audience attributes, and geo context. See [Deal Ranking and Personalization](deal-ranking-personalization.md).
    - From: `aggregationEngine`
    - To: In-process ranking pipeline
    - Protocol: In-process

14. **Blend Sponsored Ads**: `externalClients` calls Citrus Ads to obtain sponsored deal placements and inserts them into the ranked result set.
    - From: `aggregationEngine`
    - To: `citrusAdsServiceExt_19e7ad`
    - Protocol: REST/HTTP

15. **Write to Cache**: `cacheLayer` serializes the ranked response (Kryo) and writes it to Redis for future cache hits.
    - From: `cacheLayer`
    - To: `redisClusterExt_9d0c11`
    - Protocol: Redis protocol (see [Cache Warming](cache-warming.md))

16. **Return Response**: `apiResource` returns the ranked deal list as JSON to the caller.
    - From: `apiResource`
    - To: Consumer
    - Protocol: REST/HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Elasticsearch unreachable | Hystrix circuit opens; deal query skipped | Empty or cached results returned; degraded quality |
| Redis unavailable | Cache layer bypassed; aggregation proceeds | Higher latency on every request; no caching |
| Deal Catalog Service timeout | Hystrix circuit opens after threshold | Deals returned without full catalog enrichment |
| Badges Service timeout | Hystrix circuit opens | Deals returned without badge annotations |
| User Identities failure | Fallback to anonymous/non-personalized ranking | Non-personalized results returned |
| Geo Services failure | Geo context omitted | Location-based filtering degraded |
| Citrus Ads failure | Sponsored placements skipped | Organic results returned only |
| Spell Correction failure | Original query used unmodified | Potentially lower search quality |

## Sequence Diagram

```
Consumer          -> apiResource:               GET /v2/deals/search
apiResource       -> aggregationEngine:         Dispatch aggregation request
aggregationEngine -> spellCorrectionServiceExt: Correct query terms
aggregationEngine -> redisClusterExt_9d0c11:    Cache lookup
redisClusterExt   --> aggregationEngine:        MISS
aggregationEngine -> continuumUserIdentitiesService: Resolve user identity
aggregationEngine -> continuumGeoPlacesService: Resolve geo place
aggregationEngine -> continuumGeoDetailsService: Resolve geo details
aggregationEngine -> elasticsearchClusterExt:   Query deal index
aggregationEngine -> continuumDealCatalogService: Enrich deal details
aggregationEngine -> continuumBadgesService:    Fetch badges
aggregationEngine -> audienceUserAttributesServiceExt: Fetch audience attrs
aggregationEngine -> cardatronServiceExt:        Fetch card/deck data
aggregationEngine -> modelStore:                Load ML model artifacts
aggregationEngine -> aggregationEngine:         Rank and personalize
aggregationEngine -> citrusAdsServiceExt:       Fetch sponsored ads
aggregationEngine -> cacheLayer:                Write result to cache
cacheLayer        -> redisClusterExt_9d0c11:    SET serialized response
aggregationEngine --> apiResource:              Ranked deal list
apiResource       --> Consumer:                 200 OK, JSON deal list
```

## Related

- Architecture dynamic view: `darwinAggregatorServiceComponents`
- Related flows: [Async Batch Aggregation](async-batch-aggregation.md), [Deal Ranking and Personalization](deal-ranking-personalization.md), [Cache Warming](cache-warming.md)
