---
service: "dynamic_pricing"
title: "Create Retail Price"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "create-retail-price"
flow_type: synchronous
trigger: "PUT /pricing_service/v2.0/product/{id}/retail_price"
participants:
  - "continuumDynamicPricingNginx"
  - "continuumPricingService_retailPriceController"
  - "continuumPricingService_retailPriceService"
  - "continuumPricingService_priceUpdateWorkflow"
  - "continuumPricingService_pricingDbRepository"
  - "continuumPricingService_pwaDbRepository"
  - "continuumPricingService_redisCacheClient"
  - "continuumPricingService_mbusPublishers"
  - "continuumPricingDb"
  - "continuumPwaDb"
  - "continuumRedisCache"
  - "continuumMbusBroker"
architecture_ref: "dynamic-pricing-update-continuumPricingService_priceUpdateWorkflow"
---

# Create Retail Price

## Summary

This flow handles a synchronous request to update the retail price for a product. The request is proxied through NGINX, validated by the retail price service, then committed transactionally to the pricing database. Upon success, the Redis PriceSummary cache is invalidated and price change events are published to the MBus broker for downstream consumption.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum service or API consumer via `apiProxy` and `continuumDynamicPricingNginx`
- **Frequency**: On-demand, per price update operation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dynamic Pricing NGINX | Receives and proxies inbound request | `continuumDynamicPricingNginx` |
| Retail Price Controller | Accepts and parses retail price update request | `continuumPricingService_retailPriceController` |
| Retail Price Service | Orchestrates validation and triggers update pipeline | `continuumPricingService_retailPriceService` |
| Price Update Workflow | Executes transactional DB writes, cache invalidation, event publication | `continuumPricingService_priceUpdateWorkflow` |
| Pricing DB Repository | Reads and writes retail price state | `continuumPricingService_pricingDbRepository` |
| PWA DB Repository | Synchronizes price change to PWA inventory tables | `continuumPricingService_pwaDbRepository` |
| Redis Price Cache Client | Expires cached PriceSummary entry after update | `continuumPricingService_redisCacheClient` |
| MBus Producers | Publishes `dynamic.pricing.update` and `retail_price_events` | `continuumPricingService_mbusPublishers` |
| Pricing Service DB | Persists new retail price state | `continuumPricingDb` |
| PWA DB | Receives synchronized price update | `continuumPwaDb` |
| Pricing Redis Cache | PriceSummary entry expired | `continuumRedisCache` |
| MBus Broker | Receives and distributes price change events | `continuumMbusBroker` |

## Steps

1. **Receive request**: API consumer sends PUT request to `/pricing_service/v2.0/product/{id}/retail_price`.
   - From: `apiProxy`
   - To: `continuumDynamicPricingNginx`
   - Protocol: HTTPS

2. **Proxy to service**: NGINX routes the request to an available pricing write pod.
   - From: `continuumDynamicPricingNginx`
   - To: `continuumPricingService_retailPriceController`
   - Protocol: HTTP

3. **Accept and validate request**: The Retail Price Controller parses the payload and delegates to the Retail Price Service.
   - From: `continuumPricingService_retailPriceController`
   - To: `continuumPricingService_retailPriceService`
   - Protocol: direct

4. **Run validation and persistence pipeline**: Retail Price Service invokes the Price Update Workflow.
   - From: `continuumPricingService_retailPriceService`
   - To: `continuumPricingService_priceUpdateWorkflow`
   - Protocol: direct

5. **Persist new pricing state**: Workflow executes transactional write of the new retail price to the pricing database.
   - From: `continuumPricingService_pricingDbRepository`
   - To: `continuumPricingDb`
   - Protocol: JDBC

6. **Synchronize PWA parity**: Workflow writes the price change to the PWA database for inventory parity.
   - From: `continuumPricingService_pwaDbRepository`
   - To: `continuumPwaDb`
   - Protocol: JDBC

7. **Expire cache entry**: Workflow instructs the Redis cache client to invalidate the PriceSummary entry for the product.
   - From: `continuumPricingService_redisCacheClient`
   - To: `continuumRedisCache`
   - Protocol: Redis

8. **Publish price change events**: Workflow publishes `dynamic.pricing.update` and `retail_price_events` to the MBus broker.
   - From: `continuumPricingService_mbusPublishers`
   - To: `continuumMbusBroker`
   - Protocol: JMS

9. **Return response**: Success response returned to the original caller through NGINX.
   - From: `continuumPricingService_retailPriceController`
   - To: `apiProxy` (via `continuumDynamicPricingNginx`)
   - Protocol: HTTP/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DB write failure | Transaction rolled back | Caller receives error response; no cache or event side effects |
| PWA DB write failure | Partial failure — pricing DB may have committed | Price state updated but PWA parity broken; requires remediation |
| Redis expiry failure | Non-critical; cache entry will age out naturally | Stale price may be served until TTL expires or next update |
| MBus publish failure | Price written to DB but events not sent | Downstream consumers receive no notification; manual replay may be needed |

## Sequence Diagram

```
apiProxy -> continuumDynamicPricingNginx: PUT /pricing_service/v2.0/product/{id}/retail_price
continuumDynamicPricingNginx -> continuumPricingService_retailPriceController: Proxy request (HTTP)
continuumPricingService_retailPriceController -> continuumPricingService_retailPriceService: Accept and validate retail price update
continuumPricingService_retailPriceService -> continuumPricingService_priceUpdateWorkflow: Run validation and persistence pipeline
continuumPricingService_priceUpdateWorkflow -> continuumPricingDb: Persist new pricing state (JDBC)
continuumPricingService_priceUpdateWorkflow -> continuumPwaDb: Synchronize price change (JDBC)
continuumPricingService_priceUpdateWorkflow -> continuumRedisCache: Expire PriceSummary entry (Redis)
continuumPricingService_priceUpdateWorkflow -> continuumMbusBroker: Publish dynamic.pricing.update + retail_price_events (JMS)
continuumPricingService_retailPriceController --> continuumDynamicPricingNginx: 200 OK
continuumDynamicPricingNginx --> apiProxy: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-pricing-update-continuumPricingService_priceUpdateWorkflow`
- Related flows: [Get Current Price Cache Lookup](get-current-price-cache-lookup.md), [Bulk Program Price Creation](bulk-program-price-creation.md)
