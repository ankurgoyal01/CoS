---
service: "coupons-inventory-service"
title: "Product Query by Deal ID"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "product-query-by-deal-id"
flow_type: synchronous
trigger: "API request to query products by deal-id (GET /products?dealId=)"
participants:
  - "continuumCouponsInventoryService_productApi"
  - "continuumCouponsInventoryService_productDomain"
  - "continuumCouponsInventoryService_validation"
  - "continuumCouponsInventoryService_redisClient"
  - "continuumCouponsInventoryService_productRepository"
  - "continuumCouponsInventoryService_jdbiInfrastructure"
architecture_ref: "dynamic-product-query-by-deal-id"
---

# Product Query by Deal ID

## Summary

This flow handles querying inventory products by deal identifier. The Product API receives the request, the Product Domain validates parameters, and then checks the Redis cache for precomputed deal-id lists. On a cache hit, results are returned directly. On a cache miss, the Product Repository queries Postgres and the result is cached in Redis for subsequent requests.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum service calling GET /products?dealId={dealId}
- **Frequency**: on-demand, per-request (high frequency)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Product API | Receives the HTTP query request | `continuumCouponsInventoryService_productApi` |
| Product Domain | Orchestrates cache lookup and database fallback | `continuumCouponsInventoryService_productDomain` |
| Validation & DTO Factories | Validates deal-id query parameters | `continuumCouponsInventoryService_validation` |
| Redis Client | Provides cached deal-id lists | `continuumCouponsInventoryService_redisClient` |
| Product Repository | Falls back to database query on cache miss | `continuumCouponsInventoryService_productRepository` |
| Jdbi Persistence Infrastructure | Executes SQL queries for product lookup | `continuumCouponsInventoryService_jdbiInfrastructure` |

## Steps

1. **Receive query request**: The Product API receives a GET request with a dealId query parameter.
   - From: `External caller`
   - To: `continuumCouponsInventoryService_productApi`
   - Protocol: REST (HTTP/JSON)

2. **Delegate to Product Domain**: The API resource delegates to the Product Domain.
   - From: `continuumCouponsInventoryService_productApi`
   - To: `continuumCouponsInventoryService_productDomain`
   - Protocol: JAX-RS call

3. **Validate query parameters**: The Product Domain validates the deal-id query parameter.
   - From: `continuumCouponsInventoryService_productDomain`
   - To: `continuumCouponsInventoryService_validation`
   - Protocol: In-process call

4. **Check Redis cache**: The Product Domain queries Redis for a cached deal-id list.
   - From: `continuumCouponsInventoryService_productDomain`
   - To: `continuumCouponsInventoryService_redisClient`
   - Protocol: Redis

5. **Cache hit path**: If the deal-id list is found in Redis, skip to step 8.

6. **Cache miss -- query database**: On cache miss, the Product Repository queries Postgres for products matching the deal-id.
   - From: `continuumCouponsInventoryService_productRepository`
   - To: `continuumCouponsInventoryService_jdbiInfrastructure`
   - Protocol: Jdbi, Postgres

7. **Populate Redis cache**: The result is cached in Redis for subsequent requests.
   - From: `continuumCouponsInventoryService_productRepository`
   - To: `continuumCouponsInventoryService_redisClient`
   - Protocol: Redis

8. **Return response**: The Product API returns the product list to the caller.
   - From: `continuumCouponsInventoryService_productApi`
   - To: `External caller`
   - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid deal-id parameter | Validation rejects request; HTTP 400 returned | Client receives 400 Bad Request |
| Redis unavailable | Cache miss fallback; query database directly | Request succeeds with higher latency |
| Database query failure | Jdbi throws exception | Client receives 500 Internal Server Error |
| Empty result set | No products found for deal-id | Client receives 200 OK with empty list |

## Sequence Diagram

```
Caller -> Product API: GET /products?dealId={dealId}
Product API -> Product Domain: queryByDealId(dealId)
Product Domain -> Validation: validateDealIdParam(dealId)
Validation --> Product Domain: validated
Product Domain -> Redis Client: getDealIdList(dealId)
alt cache hit
    Redis Client --> Product Domain: cached product list
else cache miss
    Redis Client --> Product Domain: null
    Product Domain -> Product Repository: findByDealId(dealId)
    Product Repository -> Jdbi Infrastructure: SELECT ... WHERE deal_id = ?
    Jdbi Infrastructure --> Product Repository: result set
    Product Repository -> Redis Client: cacheDealIdList(dealId, products)
    Product Repository --> Product Domain: product list
end
Product Domain --> Product API: product list
Product API --> Caller: 200 OK (JSON array)
```

## Related

- Architecture component view: `components-continuum-coupons-inventory-service`
- Related flows: [Product Creation](product-creation.md), [Deal ID Resolution](deal-id-resolution.md)
