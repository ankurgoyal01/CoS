---
service: "dynamic_pricing"
title: "Get Current Price Cache Lookup"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "get-current-price-cache-lookup"
flow_type: synchronous
trigger: "GET /pricing_service/v2.0/product/{id}/current_price"
participants:
  - "continuumDynamicPricingNginx"
  - "continuumPricingService_currentPriceController"
  - "continuumPricingService_currentPriceService"
  - "continuumPricingService_priceRuleService"
  - "continuumPricingService_redisCacheClient"
  - "continuumPricingService_pricingDbRepository"
  - "continuumRedisCache"
  - "continuumPricingDb"
architecture_ref: "dynamic-pricing-nginx-request-routing"
---

# Get Current Price Cache Lookup

## Summary

This flow handles a synchronous request to retrieve the current price summary for a product. The service first checks the Redis cache for a pre-computed PriceSummary. On a cache hit, the serialized summary is returned directly with minimal latency. On a cache miss, the service reads pricing state and applicable rules from the database, assembles the PriceSummary, populates the cache, and returns the result. Price rules are applied to the summary during assembly.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum services or APIs requesting current prices via `apiProxy` and `continuumDynamicPricingNginx`
- **Frequency**: High-frequency, per-request; drives the primary read path for pricing

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dynamic Pricing NGINX | Receives and routes inbound request | `continuumDynamicPricingNginx` |
| Current Price Controller | Accepts and parses GET current price request | `continuumPricingService_currentPriceController` |
| Current Price Service | Orchestrates cache check, DB fallback, rule application, and response assembly | `continuumPricingService_currentPriceService` |
| Price Rule Service | Retrieves applicable price rules for the product | `continuumPricingService_priceRuleService` |
| Redis Price Cache Client | Performs cache hit/miss check and cache population | `continuumPricingService_redisCacheClient` |
| Pricing DB Repository | Reads pricing rows on cache miss | `continuumPricingService_pricingDbRepository` |
| Pricing Redis Cache | Stores and serves PriceSummary records | `continuumRedisCache` |
| Pricing Service DB | Authoritative source of pricing state on cache miss | `continuumPricingDb` |

## Steps

1. **Receive request**: Caller sends GET to `/pricing_service/v2.0/product/{id}/current_price`.
   - From: `apiProxy`
   - To: `continuumDynamicPricingNginx`
   - Protocol: HTTPS

2. **Proxy to pricing pod**: NGINX routes to a read-capable pricing pod.
   - From: `continuumDynamicPricingNginx`
   - To: `continuumPricingService_currentPriceController`
   - Protocol: HTTP

3. **Delegate to Current Price Service**: Controller passes product ID to the Current Price Service.
   - From: `continuumPricingService_currentPriceController`
   - To: `continuumPricingService_currentPriceService`
   - Protocol: direct

4. **Check Redis cache**: Current Price Service requests PriceSummary from Redis for the product ID.
   - From: `continuumPricingService_redisCacheClient`
   - To: `continuumRedisCache`
   - Protocol: Redis

5a. **Cache hit — return summary**: If a valid PriceSummary is found in Redis, skip to step 7.

5b. **Cache miss — read from DB**: If no cache entry exists, Current Price Service reads pricing rows from `continuumPricingDb`.
   - From: `continuumPricingService_pricingDbRepository`
   - To: `continuumPricingDb`
   - Protocol: JDBC

6. **Apply price rules**: Current Price Service retrieves applicable rules from Price Rule Service and applies them to the assembled summary.
   - From: `continuumPricingService_currentPriceService`
   - To: `continuumPricingService_priceRuleService`
   - Protocol: direct

6a. **Populate cache**: Assembled PriceSummary is written back to Redis for future lookups.
   - From: `continuumPricingService_redisCacheClient`
   - To: `continuumRedisCache`
   - Protocol: Redis

7. **Return price summary**: PriceSummary is returned to the caller.
   - From: `continuumPricingService_currentPriceController`
   - To: `apiProxy` (via `continuumDynamicPricingNginx`)
   - Protocol: HTTP/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable | Falls back to DB read for every request | Higher latency; `continuumPricingDb` load increases |
| DB unavailable | Request fails | Caller receives error response; no price data returned |
| Cache miss with no DB record | Service returns not-found or empty response | Caller handles absence of pricing data |
| Rule service failure | No evidence found for explicit fallback | Price summary may be returned without rule application, or request may fail |

## Sequence Diagram

```
apiProxy -> continuumDynamicPricingNginx: GET /pricing_service/v2.0/product/{id}/current_price
continuumDynamicPricingNginx -> continuumPricingService_currentPriceController: Proxy request (HTTP)
continuumPricingService_currentPriceController -> continuumPricingService_currentPriceService: Delegate lookup
continuumPricingService_currentPriceService -> continuumRedisCache: Check PriceSummary cache (Redis)
alt Cache hit
  continuumRedisCache --> continuumPricingService_currentPriceService: PriceSummary (cached)
else Cache miss
  continuumPricingService_currentPriceService -> continuumPricingDb: Read pricing rows (JDBC)
  continuumPricingDb --> continuumPricingService_currentPriceService: Pricing data
  continuumPricingService_currentPriceService -> continuumPricingService_priceRuleService: Get applicable price rules
  continuumPricingService_priceRuleService --> continuumPricingService_currentPriceService: Price rules
  continuumPricingService_currentPriceService -> continuumRedisCache: Populate PriceSummary cache (Redis)
end
continuumPricingService_currentPriceService --> continuumPricingService_currentPriceController: PriceSummary
continuumPricingService_currentPriceController --> continuumDynamicPricingNginx: 200 OK + PriceSummary
continuumDynamicPricingNginx --> apiProxy: 200 OK + PriceSummary
```

## Related

- Architecture dynamic view: `dynamic-pricing-nginx-request-routing`
- Related flows: [Create Retail Price](create-retail-price.md), [Price Rule Schedule Job](price-rule-schedule-job.md)
- See [Data Stores](../data-stores.md) for Redis cache behavior details
