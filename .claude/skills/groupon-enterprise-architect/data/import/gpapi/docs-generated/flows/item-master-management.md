---
service: "gpapi"
title: "Item Master Management"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "item-master-management"
flow_type: synchronous
trigger: "Vendor creates or updates item attributes and pricing via Vendor Portal"
participants:
  - "continuumGpapiService"
  - "continuumGpapiDb"
  - "Pricing Service"
  - "Goods Inventory Service"
architecture_ref: "dynamic-vendorOnboardingFlow"
---

# Item Master Management

## Summary

Item master management governs the creation and maintenance of item records within gpapi, including vendor-specific pricing and inventory attributes. Items are the individual purchasable units within a product. gpapi stores the canonical item record and coordinates pricing updates with the Pricing Service and inventory allocation data with the Goods Inventory Service. The V2 API surface (`/api/v2/vendor_items`) provides the pricing-focused view of items.

## Trigger

- **Type**: api-call
- **Source**: Vendor submitting item create or update actions via Vendor Portal UI
- **Frequency**: On demand (per item create/update action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Goods Vendor Portal UI | Initiates item create/update | — |
| Goods Product API | Owns item record; coordinates pricing and inventory | `continuumGpapiService` |
| gpapi Database | Stores canonical item records | `continuumGpapiDb` |
| Pricing Service | Manages vendor item pricing | — |
| Goods Inventory Service | Manages inventory item instances | — |

## Steps

### Create Item

1. **Receive create request**: Vendor Portal UI submits new item payload with product association.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `POST /api/v1/items`
   - Protocol: REST

2. **Validate item data**: gpapi validates the item payload against product existence and required fields.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb` (validate product_id)
   - Protocol: PostgreSQL

3. **Persist item record**: gpapi writes the new item record.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

4. **Register item pricing**: gpapi calls Pricing Service to register the vendor item price.
   - From: `continuumGpapiService`
   - To: Pricing Service
   - Protocol: REST

5. **Return created item**: gpapi returns the item record to the Vendor Portal UI.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 201 Created)

### Update Item Pricing (V2)

6. **Receive pricing update**: Vendor Portal UI submits updated pricing for an existing vendor item.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `PATCH /api/v2/vendor_items/:id`
   - Protocol: REST

7. **Update item pricing in gpapi**: gpapi updates the local item price fields.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

8. **Push pricing to Pricing Service**: gpapi pushes the price change to the Pricing Service.
   - From: `continuumGpapiService`
   - To: Pricing Service (update vendor item price)
   - Protocol: REST

9. **Return updated vendor item**: gpapi returns the updated item to the Vendor Portal UI.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 200 OK)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Product not found | Return 404 Not Found | Item not created |
| Invalid pricing data | Return 422 Unprocessable Entity | Item not updated |
| Pricing Service unavailable | Return 503 or error | Pricing update fails; local record may be inconsistent |
| Goods Inventory Service unavailable | Return 503 or error | Inventory allocation unavailable |

## Sequence Diagram

```
VendorPortalUI -> continuumGpapiService: POST /api/v1/items (item data, product_id)
continuumGpapiService -> continuumGpapiDb: SELECT product (validate)
continuumGpapiDb --> continuumGpapiService: product found
continuumGpapiService -> continuumGpapiDb: INSERT item record
continuumGpapiService -> PricingService: register item price
PricingService --> continuumGpapiService: 200 OK
continuumGpapiService --> VendorPortalUI: 201 Created (item record)
```

## Related

- Architecture dynamic view: `dynamic-vendorOnboardingFlow`
- Related flows: [Product Lifecycle](product-lifecycle.md), [Contract Lifecycle](contract-lifecycle.md)
