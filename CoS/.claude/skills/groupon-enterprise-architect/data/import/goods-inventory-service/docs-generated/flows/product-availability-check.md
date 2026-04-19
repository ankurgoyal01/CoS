---
service: "goods-inventory-service"
title: "Product Availability Check"
generated: "2026-03-03"
type: flow
flow_name: "product-availability-check"
flow_type: synchronous
trigger: "API request from checkout or consumer-facing services"
participants:
  - "continuumGoodsInventoryService_apiControllers"
  - "continuumGoodsInventoryService_apiMappers"
  - "continuumGoodsInventoryService_productAndInventoryServices"
  - "continuumGoodsInventoryService_pricingIntegration"
  - "continuumGoodsInventoryService_redisCacheAccess"
  - "continuumGoodsInventoryService_inventoryDomainRepositories"
  - "continuumGoodsInventoryDb"
  - "continuumGoodsInventoryRedis"
  - "deliveryEstimatorService"
architecture_ref: "dynamic-product-availability-check"
---

# Product Availability Check

## Summary

This flow handles real-time product availability queries from consumer-facing services and checkout flows. It combines cached inventory projections with live database state, enriches the response with current pricing from the pricing cache, and optionally includes delivery estimates. The flow is optimized for low latency using Redis caching with fallback to direct database reads.

## Trigger

- **Type**: API call
- **Source**: Checkout services, GPAPI, consumer-facing APIs requesting product availability before or during checkout
- **Frequency**: On demand, high frequency (per product page view, per checkout initiation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers | Receives HTTP request, delegates to services, returns response | `continuumGoodsInventoryService_apiControllers` |
| API Mappers & Validators | Validates request parameters and maps response to API DTOs | `continuumGoodsInventoryService_apiMappers` |
| Product & Inventory Services | Orchestrates availability computation from cache or DB | `continuumGoodsInventoryService_productAndInventoryServices` |
| Pricing Integration | Enriches availability response with current pricing data | `continuumGoodsInventoryService_pricingIntegration` |
| Redis Cache Access | Reads cached inventory projections and pricing data | `continuumGoodsInventoryService_redisCacheAccess` |
| Inventory Domain Repositories | Queries inventory products and units from PostgreSQL on cache miss | `continuumGoodsInventoryService_inventoryDomainRepositories` |
| Goods Inventory DB | PostgreSQL data source for inventory state | `continuumGoodsInventoryDb` |
| Goods Inventory Redis Cache | Cache store for projections and pricing | `continuumGoodsInventoryRedis` |
| Delivery Estimator Service | Provides delivery time estimates | `deliveryEstimatorService` |

## Steps

1. **Receive availability request**: Consumer or checkout service sends GET request to availability endpoint with product ID(s) and locale.
   - From: `External Consumer`
   - To: `continuumGoodsInventoryService_apiControllers`
   - Protocol: REST/HTTP

2. **Validate request**: API Controllers pass request through API Mappers & Validators to verify required parameters and locale mapping.
   - From: `continuumGoodsInventoryService_apiControllers`
   - To: `continuumGoodsInventoryService_apiMappers`
   - Protocol: In-process

3. **Check Redis cache for inventory projection**: Product & Inventory Services attempt to read cached inventory projection from Redis.
   - From: `continuumGoodsInventoryService_productAndInventoryServices`
   - To: `continuumGoodsInventoryService_redisCacheAccess`
   - Protocol: Redis

4. **Cache hit -- return cached projection** (happy path): If cached projection exists and is fresh, skip to pricing enrichment (step 6).
   - From: `continuumGoodsInventoryService_redisCacheAccess`
   - To: `continuumGoodsInventoryRedis`
   - Protocol: Redis

5. **Cache miss -- query PostgreSQL**: On cache miss, Inventory Domain Repositories query the database for current product and unit state, then compute and cache the projection.
   - From: `continuumGoodsInventoryService_productAndInventoryServices`
   - To: `continuumGoodsInventoryService_inventoryDomainRepositories`
   - Protocol: JDBI/PostgreSQL

6. **Enrich with pricing data**: Pricing Integration retrieves current pricing from Redis cache (or fetches from Pricing Service on cache miss).
   - From: `continuumGoodsInventoryService_apiControllers`
   - To: `continuumGoodsInventoryService_pricingIntegration`
   - Protocol: In-process + Redis

7. **Fetch delivery estimates** (optional): If delivery estimates are requested, the service calls Delivery Estimator Service.
   - From: `continuumGoodsInventoryService_productAndInventoryServices`
   - To: `deliveryEstimatorService`
   - Protocol: HTTP/JSON

8. **Map and return response**: API Mappers assemble the availability response DTO with product data, pricing, and delivery estimates, returning it to the caller.
   - From: `continuumGoodsInventoryService_apiMappers`
   - To: `External Consumer`
   - Protocol: REST/HTTP (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis cache unavailable | Fall back to direct PostgreSQL query | Higher latency but correct data |
| PostgreSQL query failure | Return 500 error with structured error response | Consumer retries or shows unavailable |
| Pricing data unavailable | Return availability without pricing enrichment | Partial response; consumer handles missing pricing |
| Delivery Estimator timeout | Return availability without delivery estimates | Partial response; delivery info omitted |
| Invalid product ID | Return 404 with error details | Consumer handles not-found |

## Sequence Diagram

```
Consumer -> API Controllers: GET /availability/:productId
API Controllers -> API Mappers: Validate request
API Mappers --> API Controllers: Validated params
API Controllers -> Product & Inventory Services: getAvailability(productId)
Product & Inventory Services -> Redis Cache Access: getCachedProjection(productId)
Redis Cache Access -> Redis: GET inv-projection:{productId}
Redis --> Redis Cache Access: cached projection (or miss)
alt Cache miss
  Product & Inventory Services -> Inventory Domain Repositories: queryAvailability(productId)
  Inventory Domain Repositories -> PostgreSQL: SELECT inventory data
  PostgreSQL --> Inventory Domain Repositories: Result set
  Inventory Domain Repositories --> Product & Inventory Services: Availability data
  Product & Inventory Services -> Redis Cache Access: cacheProjection(productId, data)
end
API Controllers -> Pricing Integration: enrichWithPricing(productId)
Pricing Integration -> Redis Cache Access: getCachedPricing(productId)
Redis Cache Access --> Pricing Integration: Pricing data
Pricing Integration --> API Controllers: Enriched data
API Controllers -> API Mappers: mapToResponse(data)
API Mappers --> API Controllers: AvailabilityResponse DTO
API Controllers --> Consumer: 200 OK (JSON)
```

## Related

- Architecture dynamic view: `dynamic-product-availability-check`
- Related flows: [Reservation Creation](reservation-creation.md), [Inventory Sync with IMS](inventory-sync-ims.md)
