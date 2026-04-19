---
service: "deal-management-api"
title: "Inventory Product and Pricing Update"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "inventory-product-pricing-update"
flow_type: synchronous
trigger: "HTTP POST/PUT /v2/inventory_products"
participants:
  - "continuumDealManagementApi"
  - "continuumDealManagementMysql"
  - "continuumPricingService"
  - "continuumVoucherInventoryService"
  - "continuumCouponsInventoryService"
  - "continuumGoodsInventoryService"
  - "continuumThirdPartyInventoryService"
  - "continuumCloInventoryService"
architecture_ref: "dynamic-inventoryProductPricingUpdate"
---

# Inventory Product and Pricing Update

## Summary

The inventory product and pricing update flow handles the configuration of inventory products associated with a deal, including setting or updating pricing attributes. The API fetches current pricing rules from the Pricing Service, validates the inventory product configuration, persists the updated record to MySQL, and confirms the update with the relevant inventory service for the deal type (Voucher, Coupons, Goods, ThirdParty, or CLO).

## Trigger

- **Type**: api-call
- **Source**: Deal setup tooling configuring inventory and pricing for a deal
- **Frequency**: On demand (during deal setup or repricing)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Management API | Orchestrates validation and inventory product update | `continuumDealManagementApi` |
| Deal Management MySQL | Persists inventory product and pricing records | `continuumDealManagementMysql` |
| Pricing Service | Provides applicable pricing rules for the deal | `continuumPricingService` |
| Voucher Inventory Service | Confirms inventory update for voucher deals | `continuumVoucherInventoryService` |
| Coupons Inventory Service | Confirms inventory update for coupon deals | `continuumCouponsInventoryService` |
| Goods Inventory Service | Confirms inventory update for goods deals | `continuumGoodsInventoryService` |
| Third-Party Inventory Service | Confirms inventory update for third-party deals | `continuumThirdPartyInventoryService` |
| CLO Inventory Service | Confirms inventory update for CLO deals | `continuumCloInventoryService` |

## Steps

1. **Receive inventory product request**: API Controllers accept POST `/v2/inventory_products` (create) or PUT `/v2/inventory_products/:id` (update) with pricing and inventory configuration payload.
   - From: Calling client
   - To: `continuumDealManagementApi` (`apiControllers`)
   - Protocol: REST/HTTPS

2. **Validate inventory product payload**: Validators confirm required fields, pricing constraints, and deal association.
   - From: `apiControllers`
   - To: `validationLayer` (internal)
   - Protocol: in-process

3. **Fetch current pricing rules**: Remote Clients call the Pricing Service to retrieve applicable pricing rules for the deal type and market.
   - From: `continuumDealManagementApi` (`remoteClients`)
   - To: `continuumPricingService`
   - Protocol: REST/HTTPS

4. **Validate pricing against rules**: Validators confirm that the submitted pricing values comply with retrieved pricing rules.
   - From: `validationLayer` (internal)
   - To: in-process
   - Protocol: in-process

5. **Persist inventory product record**: Repositories write the inventory product and pricing attributes to MySQL.
   - From: `continuumDealManagementApi` (`repositories`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

6. **Notify relevant inventory service**: Remote Clients call the appropriate inventory service for the deal type to register or update the inventory product entry.
   - From: `continuumDealManagementApi` (`remoteClients`)
   - To: Applicable inventory service (Voucher / Coupons / Goods / ThirdParty / CLO)
   - Protocol: REST/HTTPS

7. **Return updated inventory product**: API Controllers return HTTP 200 or 201 with the updated inventory product record.
   - From: `continuumDealManagementApi`
   - To: Calling client
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure | Return HTTP 422 with field-level errors | Inventory product not updated |
| Pricing Service unavailable | Return HTTP 503 | Update blocked; pricing cannot be validated |
| Pricing rule violation | Return HTTP 422 with pricing constraint details | Update rejected |
| MySQL write failure | Return HTTP 500; transaction rolled back | Inventory product not updated |
| Inventory service unavailable | Return HTTP 503 | Update may be persisted locally but not confirmed with inventory system |
| Inventory service returns conflict | Return HTTP 422 or 409 | Caller must resolve conflict and retry |

## Sequence Diagram

```
Client -> continuumDealManagementApi: POST /v2/inventory_products {product + pricing data}
continuumDealManagementApi -> validationLayer: validate(payload)
validationLayer --> continuumDealManagementApi: valid / errors
continuumDealManagementApi -> continuumPricingService: GET pricing rules for deal type
continuumPricingService --> continuumDealManagementApi: pricing rules
continuumDealManagementApi -> validationLayer: validate pricing against rules
validationLayer --> continuumDealManagementApi: pricing valid
continuumDealManagementApi -> continuumDealManagementMysql: INSERT/UPDATE inventory_product
continuumDealManagementMysql --> continuumDealManagementApi: product_id
continuumDealManagementApi -> InventoryService: POST/PUT inventory product entry
InventoryService --> continuumDealManagementApi: 200/201 OK
continuumDealManagementApi --> Client: 201 Created {inventory_product}
```

## Related

- Architecture dynamic view: `dynamic-inventoryProductPricingUpdate`
- Related flows: [Deal Create (Sync)](deal-create-sync.md), [Deal Publish Workflow](deal-publish-workflow.md)
