---
service: "clo-inventory-service"
title: "Inventory Product Creation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "inventory-product-creation"
flow_type: synchronous
trigger: "HTTP POST request to create a CLO inventory product"
participants:
  - "continuumCloInventoryService_httpApiInventory"
  - "continuumCloInventoryService_facades"
  - "continuumCloInventoryService_coreProductService"
  - "continuumCloInventoryService_corePricingService"
  - "continuumCloInventoryService_externalIntegrations"
  - "continuumCloInventoryService_persistenceRepositories"
  - "continuumCloInventoryService_dataAccessPostgres"
  - "continuumCloInventoryService_dataAccessRedisAndMemory"
  - "continuumCloInventoryDb"
  - "continuumCloInventoryRedisCache"
  - "continuumDealCatalogService"
  - "continuumM3MerchantService"
  - "continuumCloCoreService"
architecture_ref: "components-continuum-clo-continuumCloInventoryService_httpApiInventory-continuumCloInventoryService_coreProductService"
---

# Inventory Product Creation

## Summary

The Inventory Product Creation flow handles the creation of a new CLO inventory product. When a product creation request arrives via the REST API, the service aggregates data from the Deal Catalog Service (deal metadata and pricing), the M3 Merchant Service (merchant features), and the IS-Core Pricing Service (dynamic pricing decisions). It persists the enriched product to PostgreSQL, updates the Redis cache, and synchronizes the corresponding CLO offer to the CLO Core Service. This flow is the foundation for making card-linked offers available to consumers.

## Trigger

- **Type**: api-call
- **Source**: HTTP POST to `/clo/products` via `CloProductResource`
- **Frequency**: On-demand, triggered by CLO product setup tooling or upstream orchestration

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API - Inventory | Receives the product creation HTTP request and delegates to the facade | `continuumCloInventoryService_httpApiInventory` |
| Domain Facades | Routes the product creation operation to the Product Service | `continuumCloInventoryService_facades` |
| Product Service | Orchestrates product creation: enrichment, pricing, persistence, and offer sync | `continuumCloInventoryService_coreProductService` |
| Pricing Service Client | Provides dynamic pricing decisions for the product | `continuumCloInventoryService_corePricingService` |
| External Service Integrations | Calls Deal Catalog, M3 Merchant, and CLO Core services | `continuumCloInventoryService_externalIntegrations` |
| Domain Repositories | Encapsulates product persistence logic | `continuumCloInventoryService_persistenceRepositories` |
| Postgres Data Access | Executes SQL insert/update for the product record | `continuumCloInventoryService_dataAccessPostgres` |
| Cache Data Access | Updates Redis and in-memory caches with the new product | `continuumCloInventoryService_dataAccessRedisAndMemory` |
| CLO Inventory Database | Stores the product record | `continuumCloInventoryDb` |
| CLO Inventory Redis Cache | Caches the new product for fast reads | `continuumCloInventoryRedisCache` |
| Deal Catalog Service | Provides deal metadata for product enrichment | `continuumDealCatalogService` |
| M3 Merchant Service | Provides merchant metadata and features | `continuumM3MerchantService` |
| CLO Core Service | Receives the synchronized CLO offer | `continuumCloCoreService` |

## Steps

1. **Receive product creation request**: HTTP API - Inventory (`CloProductResource`) receives a POST request with product creation payload
   - From: External caller
   - To: `continuumCloInventoryService_httpApiInventory`
   - Protocol: REST (HTTP/JSON)

2. **Delegate to facade**: The API resource invokes `ProductsFacade` for the product creation operation
   - From: `continuumCloInventoryService_httpApiInventory`
   - To: `continuumCloInventoryService_facades`
   - Protocol: In-process call

3. **Invoke Product Service**: The facade delegates to `CloProductService` / `CreateOrUpdateProductAggregator` which orchestrates the creation
   - From: `continuumCloInventoryService_facades`
   - To: `continuumCloInventoryService_coreProductService`
   - Protocol: In-process call

4. **Fetch deal metadata**: Product Service calls External Service Integrations to fetch deal details from the Deal Catalog Service
   - From: `continuumCloInventoryService_coreProductService`
   - To: `continuumCloInventoryService_externalIntegrations` -> `continuumDealCatalogService`
   - Protocol: HTTP/JSON via `DealCatalogClient`

5. **Fetch merchant metadata**: Product Service calls External Service Integrations to fetch merchant features from M3 Merchant Service
   - From: `continuumCloInventoryService_coreProductService`
   - To: `continuumCloInventoryService_externalIntegrations` -> `continuumM3MerchantService`
   - Protocol: HTTP/JSON via `M3MerchantClient`

6. **Obtain pricing decisions**: Product Service calls the Pricing Service Client for dynamic pricing
   - From: `continuumCloInventoryService_coreProductService`
   - To: `continuumCloInventoryService_corePricingService`
   - Protocol: In-process call (IS-Core pricing client)

7. **Persist product to PostgreSQL**: Product Service uses Domain Repositories to persist the enriched product via Postgres Data Access
   - From: `continuumCloInventoryService_coreProductService` -> `continuumCloInventoryService_persistenceRepositories` -> `continuumCloInventoryService_dataAccessPostgres`
   - To: `continuumCloInventoryDb`
   - Protocol: JDBI over JDBC / PostgreSQL

8. **Update Redis cache**: Domain Repositories update the Cache Data Access layer with the new product data
   - From: `continuumCloInventoryService_persistenceRepositories` -> `continuumCloInventoryService_dataAccessRedisAndMemory`
   - To: `continuumCloInventoryRedisCache`
   - Protocol: Redis

9. **Synchronize CLO offer**: Product Service calls External Service Integrations to create or update the corresponding CLO offer in CLO Core Service
   - From: `continuumCloInventoryService_coreProductService` -> `continuumCloInventoryService_externalIntegrations`
   - To: `continuumCloCoreService`
   - Protocol: HTTP/JSON via `CloClient` / `CloServiceClient`

10. **Return response**: The response flows back through the facade and API layer to the caller with the created product details
    - From: `continuumCloInventoryService_httpApiInventory`
    - To: External caller
    - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog Service unavailable | Product creation fails; HTTP 502/503 returned | Caller must retry; no partial state persisted |
| M3 Merchant Service unavailable | Product creation fails or proceeds with partial enrichment depending on merchant data criticality | Degraded product record may be created; or caller must retry |
| Pricing Service error | Product creation fails; pricing is required for valid product | Caller must retry; no product persisted |
| PostgreSQL write failure | Transaction rolled back; HTTP 500 returned | No product persisted; caller must retry |
| CLO Core Service unavailable (offer sync) | Product persisted locally but offer sync fails; offer may be synced on next update | Product exists in inventory but CLO offer may not yet be active on the core platform |
| Redis cache update failure | Product persisted to PostgreSQL; cache update is non-critical | Product available via database reads; cache will be populated on next read-through |

## Sequence Diagram

```
Caller -> HTTP API - Inventory: POST /clo/products (product creation payload)
HTTP API - Inventory -> Domain Facades: createProduct()
Domain Facades -> Product Service: createProduct()
Product Service -> External Integrations: fetchDealDetails(dealId)
External Integrations -> Deal Catalog Service: GET /deals/{id} (HTTP/JSON)
Deal Catalog Service --> External Integrations: Deal metadata
Product Service -> External Integrations: fetchMerchantFeatures(merchantId)
External Integrations -> M3 Merchant Service: GET /merchants/{id} (HTTP/JSON)
M3 Merchant Service --> External Integrations: Merchant metadata
Product Service -> Pricing Service Client: getPricingDecision(productData)
Pricing Service Client --> Product Service: Pricing decision
Product Service -> Domain Repositories: saveProduct(enrichedProduct)
Domain Repositories -> Postgres Data Access: insert(product)
Postgres Data Access -> CLO Inventory DB: INSERT INTO clo_products (SQL)
CLO Inventory DB --> Postgres Data Access: Confirmation
Domain Repositories -> Cache Data Access: cacheProduct(product)
Cache Data Access -> CLO Inventory Redis Cache: SET product:{id} (Redis)
Product Service -> External Integrations: syncOffer(product)
External Integrations -> CLO Core Service: POST /offers (HTTP/JSON)
CLO Core Service --> External Integrations: Offer created
Product Service --> Domain Facades: Created product
Domain Facades --> HTTP API - Inventory: Created product
HTTP API - Inventory --> Caller: 201 Created (product JSON)
```

## Related

- Architecture dynamic view: not yet defined -- see `components-continuum-clo-continuumCloInventoryService_httpApiInventory-continuumCloInventoryService_coreProductService`
- Related flows: [CLO Offer Claim](clo-offer-claim.md), [Consent Management](consent-management.md)
- See [Integrations](../integrations.md) for Deal Catalog, M3 Merchant, and CLO Core Service details
- See [Data Stores](../data-stores.md) for PostgreSQL and Redis details
