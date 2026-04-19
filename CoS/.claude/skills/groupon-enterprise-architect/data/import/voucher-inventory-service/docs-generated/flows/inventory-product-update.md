---
service: "voucher-inventory-service"
title: "Inventory Product Update"
generated: "2026-03-03"
type: flow
flow_name: "inventory-product-update"
flow_type: synchronous
trigger: "API call from deal management or internal tools"
participants:
  - "continuumVoucherInventoryApi"
  - "continuumVoucherInventoryApi_inventoryProductsApi"
  - "continuumVoucherInventoryApi_inventoryProductManager"
  - "continuumVoucherInventoryApi_pricingClient"
  - "continuumVoucherInventoryApi_dealCatalogClient"
  - "continuumVoucherInventoryApi_inventoryDataAccessors"
  - "continuumVoucherInventoryApi_cacheAccessors"
  - "continuumVoucherInventoryApi_inventoryProductsMessageProducer"
  - "continuumVoucherInventoryDb"
  - "continuumVoucherInventoryMessageBus"
architecture_ref: "dynamic-continuum-voucher-inventory"
---

# Inventory Product Update

## Summary

The inventory product update flow handles changes to inventory product configuration, attributes, and metadata. When an update request arrives, the service validates the changes, synchronizes pricing with the Pricing Service, synchronizes deal metadata with Deal Catalog, persists the updates to the product database, and publishes an inventory product updated event for downstream consumers (Deal Catalog, Lazlo, analytics).

## Trigger

- **Type**: api-call
- **Source**: Deal management tools, internal services calling inventory product update endpoints
- **Frequency**: per-request (each product configuration change)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Voucher Inventory API | Entry point, routes HTTP request | `continuumVoucherInventoryApi` |
| Inventory Products API | Handles product update HTTP endpoints | `continuumVoucherInventoryApi_inventoryProductsApi` |
| Inventory Product Manager | Orchestrates product update logic | `continuumVoucherInventoryApi_inventoryProductManager` |
| Pricing Client | Synchronizes dynamic pricing information | `continuumVoucherInventoryApi_pricingClient` |
| Deal Catalog Client | Synchronizes deal metadata and creative content | `continuumVoucherInventoryApi_dealCatalogClient` |
| Inventory Data Accessors | Persists product configuration | `continuumVoucherInventoryApi_inventoryDataAccessors` |
| Cache & Lock Accessors | Manages product-level caching and locks | `continuumVoucherInventoryApi_cacheAccessors` |
| Inventory Products Message Producer | Publishes product updated event | `continuumVoucherInventoryApi_inventoryProductsMessageProducer` |
| Voucher Inventory DB | Stores product configuration | `continuumVoucherInventoryDb` |
| Voucher Inventory Message Bus | Receives published events | `continuumVoucherInventoryMessageBus` |

## Steps

1. **Receive product update request**: Client sends PUT to inventory product endpoint with updated attributes.
   - From: External caller
   - To: `continuumVoucherInventoryApi_inventoryProductsApi`
   - Protocol: REST/HTTPS

2. **Delegate to product manager**: API delegates to Inventory Product Manager for update orchestration.
   - From: `continuumVoucherInventoryApi_inventoryProductsApi`
   - To: `continuumVoucherInventoryApi_inventoryProductManager`
   - Protocol: Ruby method calls

3. **Sync pricing**: Product Manager updates dynamic pricing information via the Pricing Client.
   - From: `continuumVoucherInventoryApi_inventoryProductManager`
   - To: `continuumVoucherInventoryApi_pricingClient`
   - Protocol: HTTPS/JSON

4. **Sync deal metadata**: Product Manager synchronizes deal metadata and creative content via the Deal Catalog Client.
   - From: `continuumVoucherInventoryApi_inventoryProductManager`
   - To: `continuumVoucherInventoryApi_dealCatalogClient`
   - Protocol: HTTPS/JSON

5. **Persist product updates**: Product Manager persists the updated configuration to the product database.
   - From: `continuumVoucherInventoryApi_inventoryProductManager`
   - To: `continuumVoucherInventoryApi_inventoryDataAccessors`
   - Protocol: ActiveRecord/SQL

6. **Update cache**: Invalidate or update cached product data in Redis.
   - From: `continuumVoucherInventoryApi_inventoryProductManager`
   - To: `continuumVoucherInventoryApi_cacheAccessors`
   - Protocol: Redis

7. **Publish product updated event**: Publish an inventory product updated event to the message bus.
   - From: `continuumVoucherInventoryApi_inventoryProductsMessageProducer`
   - To: `continuumVoucherInventoryMessageBus`
   - Protocol: JMS topics

8. **Return update confirmation**: Return success with updated product details.
   - From: `continuumVoucherInventoryApi_inventoryProductsApi`
   - To: External caller
   - Protocol: REST/HTTPS (response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Pricing Service unavailable | Log warning, continue with stale pricing | Product updated with note about pricing sync failure |
| Deal Catalog Service unavailable | Log warning, continue without metadata sync | Product updated with note about catalog sync failure |
| Database write failure | Transaction rollback | Return 500 |
| Event publish failure | Log error, event will be retried via async publisher | Product saved but event delivery delayed |

## Sequence Diagram

```
Client -> Inventory Products API: PUT /v2/inventory_products/:id
Inventory Products API -> Inventory Product Manager: updateProduct(productId, attributes)
Inventory Product Manager -> Pricing Client: syncPricing(productId)
Pricing Client --> Inventory Product Manager: pricingUpdated
Inventory Product Manager -> Deal Catalog Client: syncDealMetadata(productId)
Deal Catalog Client --> Inventory Product Manager: metadataUpdated
Inventory Product Manager -> Inventory Data Accessors: persistProduct(productData)
Inventory Data Accessors -> Voucher Inventory DB: UPDATE inventory_products
Inventory Product Manager -> Cache & Lock Accessors: invalidateCache(productId)
Inventory Product Manager -> Message Producer: publishProductUpdated(productId)
Message Producer -> Message Bus: publish(voucher_inventory.inventory_product.updated)
Inventory Product Manager --> Inventory Products API: updatedProduct
Inventory Products API --> Client: 200 OK {productDetails}
```

## Related

- Architecture dynamic view: `dynamic-continuum-voucher-inventory`
- Related flows: [Inventory Reservation](inventory-reservation.md)
