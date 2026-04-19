---
service: "coupons-inventory-service"
title: "Product Creation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "product-creation"
flow_type: synchronous + asynchronous
trigger: "API request to create a new inventory product (POST /products)"
participants:
  - "continuumCouponsInventoryService_productApi"
  - "continuumCouponsInventoryService_productDomain"
  - "continuumCouponsInventoryService_validation"
  - "continuumCouponsInventoryService_productRepository"
  - "continuumCouponsInventoryService_localizedContentRepository"
  - "continuumCouponsInventoryService_jdbiInfrastructure"
  - "continuumCouponsInventoryService_redisClient"
  - "continuumCouponsInventoryService_messagePublisher"
  - "continuumCouponsInventoryMessageBus"
architecture_ref: "dynamic-product-creation"
---

# Product Creation

## Summary

This flow covers the creation of a new inventory product through the REST API. The Product API receives the request, delegates to the Product Domain for validation, persistence, localization, caching, and event publication. After the product is persisted to Postgres and localized content is saved, an `inventoryProduct.create` event is published to the IS Core Message Bus, triggering asynchronous deal-id resolution (see [Deal ID Resolution](deal-id-resolution.md)).

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum service calling POST /products
- **Frequency**: on-demand, per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Product API | Receives the HTTP request and delegates to the domain facade | `continuumCouponsInventoryService_productApi` |
| Product Domain | Orchestrates validation, persistence, localization, caching, and event publishing | `continuumCouponsInventoryService_productDomain` |
| Validation & DTO Factories | Validates the product creation request and parameters | `continuumCouponsInventoryService_validation` |
| Product Repository | Persists the product record to Postgres | `continuumCouponsInventoryService_productRepository` |
| Localized Content Repository | Saves localized content records for the product | `continuumCouponsInventoryService_localizedContentRepository` |
| Jdbi Persistence Infrastructure | Provides DAO and mapper layer for database operations | `continuumCouponsInventoryService_jdbiInfrastructure` |
| Redis Client | Caches product data for subsequent queries | `continuumCouponsInventoryService_redisClient` |
| Message Bus Publisher | Publishes the inventoryProduct.create event | `continuumCouponsInventoryService_messagePublisher` |
| IS Core Message Bus | Receives and delivers the creation event | `continuumCouponsInventoryMessageBus` |

## Steps

1. **Receive product creation request**: The Product API receives a POST request with product data from an authenticated client.
   - From: `External caller`
   - To: `continuumCouponsInventoryService_productApi`
   - Protocol: REST (HTTP/JSON)

2. **Delegate to Product Domain**: The API resource delegates to the Product Domain facade for business logic processing.
   - From: `continuumCouponsInventoryService_productApi`
   - To: `continuumCouponsInventoryService_productDomain`
   - Protocol: JAX-RS call

3. **Validate product request**: The Product Domain invokes the Validation component to validate request parameters and product data.
   - From: `continuumCouponsInventoryService_productDomain`
   - To: `continuumCouponsInventoryService_validation`
   - Protocol: In-process call

4. **Persist product to database**: The Product Domain persists the product record via the Product Repository and Jdbi infrastructure.
   - From: `continuumCouponsInventoryService_productDomain`
   - To: `continuumCouponsInventoryService_productRepository`
   - Protocol: Jdbi, Postgres

5. **Save localized content**: The Product Domain saves associated localized content via the Localized Content Repository.
   - From: `continuumCouponsInventoryService_productDomain`
   - To: `continuumCouponsInventoryService_localizedContentRepository`
   - Protocol: Jdbi, Postgres

6. **Cache product data**: The Product Domain caches the product data in Redis for subsequent queries.
   - From: `continuumCouponsInventoryService_productDomain`
   - To: `continuumCouponsInventoryService_redisClient`
   - Protocol: Redis

7. **Publish creation event**: The Product Domain publishes an inventoryProduct.create event via the Message Bus Publisher.
   - From: `continuumCouponsInventoryService_productDomain`
   - To: `continuumCouponsInventoryService_messagePublisher`
   - Protocol: Mbus

8. **Deliver event to message bus**: The Message Bus Publisher sends the event to the IS Core Message Bus for asynchronous processing.
   - From: `continuumCouponsInventoryService_messagePublisher`
   - To: `continuumCouponsInventoryMessageBus`
   - Protocol: Mbus

9. **Return response**: The Product API returns the created product response to the caller.
   - From: `continuumCouponsInventoryService_productApi`
   - To: `External caller`
   - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure | Validation component rejects request; exception mapper returns HTTP 400 | Client receives 400 Bad Request with error details |
| Database write failure | Jdbi throws exception; transaction rolls back | Client receives 500 Internal Server Error; no product created |
| Localized content save failure | Exception during localized content persistence | Product may be partially created; error returned to client |
| Redis cache failure | Cache write fails; non-blocking | Product created successfully; cache populated on next read |
| Message bus publish failure | Event not published; deal-id resolution delayed | Product created but deal-id will not be resolved until event is successfully published |

## Sequence Diagram

```
Caller -> Product API: POST /products (JSON body)
Product API -> Product Domain: createProduct(request)
Product Domain -> Validation: validateProductRequest(request)
Validation --> Product Domain: validated
Product Domain -> Product Repository: saveProduct(product)
Product Repository -> Jdbi Infrastructure: insert(product)
Jdbi Infrastructure --> Product Repository: product persisted
Product Domain -> Localized Content Repository: saveContent(product, content)
Localized Content Repository -> Jdbi Infrastructure: insert(content)
Product Domain -> Redis Client: cacheProduct(product)
Product Domain -> Message Bus Publisher: publishCreation(product)
Message Bus Publisher -> IS Core Message Bus: inventoryProduct.create event
Product Domain --> Product API: product created
Product API --> Caller: 201 Created (product JSON)
```

## Related

- Architecture component view: `components-continuum-coupons-inventory-service`
- Related flows: [Deal ID Resolution](deal-id-resolution.md) (asynchronous continuation), [Product Query by Deal ID](product-query-by-deal-id.md)
