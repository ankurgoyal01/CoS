---
service: "vouchercloud-idl"
title: "Offer Discovery and Search"
generated: "2026-03-03"
type: flow
flow_name: "offer-discovery-and-search"
flow_type: synchronous
trigger: "Consumer or partner sends GET request to /offers, /offers/featured, /offers/popular, /offers/search, or /merchants/{id}/offers"
participants:
  - "continuumVcWebSite"
  - "continuumWhiteLabelWebSite"
  - "continuumRestfulApi"
  - "continuumVcRedisCache"
  - "continuumVcMongoDb"
  - "algoliaSearch_41e0"
architecture_ref: "dynamic-vouchercloud-idl"
---

# Offer Discovery and Search

## Summary

This flow describes how consumer-facing web and partner surfaces retrieve offer listings from the Vouchercloud Restful API. All offer listing endpoints implement a cache-aside pattern: Redis is checked first and, on a miss, the request is fulfilled from MongoDB (for structured queries) or Algolia (for full-text search). Slow MongoDB queries exceeding 300 ms are logged for diagnostics.

## Trigger

- **Type**: api-call
- **Source**: `continuumVcWebSite`, `continuumWhiteLabelWebSite`, mobile apps, or external API partners
- **Frequency**: per-request (high volume, primary consumer-facing flow)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Vouchercloud Web | Initiates offer list/detail requests | `continuumVcWebSite` |
| White Label Web | Initiates offer requests for partner brand | `continuumWhiteLabelWebSite` |
| Vouchercloud Restful API | Receives request, orchestrates cache and data retrieval | `continuumRestfulApi` |
| Vouchercloud Redis | Cache layer (cache-aside) | `continuumVcRedisCache` |
| Vouchercloud MongoDB | Primary document store for offer/merchant data | `continuumVcMongoDb` |
| Algolia | Full-text search index (search flow only) | `algoliaSearch_41e0` |

## Steps

1. **Receives offer request**: Consumer client sends GET request with `X-ApiKey` header.
   - From: `continuumVcWebSite` / `continuumWhiteLabelWebSite`
   - To: `continuumRestfulApi`
   - Protocol: REST (HTTPS)

2. **Validates API key**: `ApiKeyAuthorisation` filter validates `X-ApiKey` against known API key registry.
   - From: `continuumRestfulApi` (filter)
   - To: `continuumVcSqlDb` (API key lookup)
   - Protocol: SQL

3. **Checks Redis cache**: `IApiCacheHandler` computes cache key from request parameters and checks Redis.
   - From: `continuumRestfulApi`
   - To: `continuumVcRedisCache`
   - Protocol: Redis

4. **Returns cached response (cache hit)**: If found in Redis, response is returned immediately to caller without hitting MongoDB.
   - From: `continuumVcRedisCache`
   - To: `continuumRestfulApi`
   - To: caller
   - Protocol: Redis / REST

5. **Queries MongoDB (cache miss)**: On cache miss, the appropriate query (`IPopularOffersQuery`, `IFeaturedOffersQuery`, `IOfferDetailsQuery`, etc.) executes against MongoDB.
   - From: `continuumRestfulApi`
   - To: `continuumVcMongoDb`
   - Protocol: MongoDB wire protocol

6. **Queries Algolia (search flow only)**: If the request is to `/offers/search`, the `ISearchOffersByTermQuery` dispatches to Algolia instead of MongoDB.
   - From: `continuumRestfulApi`
   - To: `algoliaSearch_41e0`
   - Protocol: REST (Algolia SDK)

7. **Populates Redis cache**: Query result is written back to Redis with appropriate TTL.
   - From: `continuumRestfulApi`
   - To: `continuumVcRedisCache`
   - Protocol: Redis

8. **Returns response**: Paginated offer list or detail response returned to caller.
   - From: `continuumRestfulApi`
   - To: caller
   - Protocol: REST (HTTPS, JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unreachable | Cache bypass; proceeds to MongoDB directly | Offer returned; cache not populated; increased MongoDB load |
| MongoDB query timeout or error | HTTP 500 returned to caller; logged via NLog | Error response; no fallback |
| Algolia search failure | HTTP 500 or empty results returned | Search returns empty; offer listings via MongoDB unaffected |
| Invalid API key | HTTP 401 returned by `ApiKeyAuthorisation` | Request rejected |
| Slow MongoDB query (>300 ms) | Logged at WARN level in NLog | Request completes; performance alert surfaced in logs |

## Sequence Diagram

```
Client -> continuumRestfulApi: GET /offers?country=gb&category=fashion (X-ApiKey)
continuumRestfulApi -> continuumRestfulApi: ValidateApiKey
continuumRestfulApi -> continuumVcRedisCache: GET cache_key
continuumVcRedisCache --> continuumRestfulApi: MISS
continuumRestfulApi -> continuumVcMongoDb: Query offers (IPopularOffersQuery)
continuumVcMongoDb --> continuumRestfulApi: Offer documents
continuumRestfulApi -> continuumVcRedisCache: SET cache_key (TTL)
continuumRestfulApi --> Client: 200 OK { offers: [...], links: { next: ... } }
```

## Related

- Architecture dynamic view: `dynamic-vouchercloud-idl`
- Related flows: [Offer Redemption (Wallet)](offer-redemption-wallet.md), [Affiliate Outlink and Click Tracking](affiliate-outlink-click-tracking.md)
