---
service: "gpapi"
title: "Product Lifecycle"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "product-lifecycle"
flow_type: synchronous
trigger: "Vendor submits product create, update, or deactivate action via Vendor Portal"
participants:
  - "continuumGpapiService"
  - "continuumGpapiDb"
  - "Goods Product Catalog"
  - "Deal Catalog"
  - "Taxonomy Service"
architecture_ref: "dynamic-vendorOnboardingFlow"
---

# Product Lifecycle

## Summary

The product lifecycle flow governs how goods products are created, updated, approved, and deactivated within the Goods Vendor Portal. gpapi owns the canonical product record in its PostgreSQL database and synchronizes state changes to the Goods Product Catalog. Products progress through states (draft, pending approval, active, deactivated) via vendor and Groupon admin actions. Taxonomy and category lookups are performed via the Taxonomy Service during creation and updates.

## Trigger

- **Type**: api-call
- **Source**: Vendor or Groupon admin submitting a product action via Vendor Portal UI
- **Frequency**: On demand (per product create/update/deactivate action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Goods Vendor Portal UI | Initiates product actions | — |
| Goods Product API | Owns product record; orchestrates catalog synchronization | `continuumGpapiService` |
| gpapi Database | Stores canonical product records and approval state | `continuumGpapiDb` |
| Taxonomy Service | Provides category and taxonomy validation | — |
| Goods Product Catalog | Downstream product catalog synchronized on state changes | — |
| Deal Catalog | Reflects active product/deal data downstream | — |

## Steps

### Create Product

1. **Receive create request**: Vendor Portal UI submits new product payload.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `POST /api/v1/products`
   - Protocol: REST

2. **Validate taxonomy**: gpapi calls Taxonomy Service to validate the submitted category.
   - From: `continuumGpapiService`
   - To: Taxonomy Service `GET /categories/:id`
   - Protocol: REST

3. **Persist product record**: gpapi writes new product record with status `draft`.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

4. **Notify catalog**: gpapi pushes the draft product to Goods Product Catalog.
   - From: `continuumGpapiService`
   - To: Goods Product Catalog
   - Protocol: REST

5. **Return created product**: gpapi returns the product record to Vendor Portal UI.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 201 Created)

### Approve Product (status transition to active)

6. **Receive approval action**: Admin submits approval for a pending product.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `PATCH /api/v1/products/:id` (status: active)
   - Protocol: REST

7. **Update approval record**: gpapi writes approval record and transitions product status to `active`.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

8. **Synchronize catalog**: gpapi updates the Goods Product Catalog with the active product state.
   - From: `continuumGpapiService`
   - To: Goods Product Catalog
   - Protocol: REST

9. **Return updated product**: gpapi returns the approved product to the requestor.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 200 OK)

### Deactivate Product

10. **Receive deactivation request**: Vendor or admin submits deactivation.
    - From: Goods Vendor Portal UI
    - To: `continuumGpapiService` `DELETE /api/v1/products/:id`
    - Protocol: REST

11. **Update product status**: gpapi transitions product to `deactivated` in its database.
    - From: `continuumGpapiService`
    - To: `continuumGpapiDb`
    - Protocol: PostgreSQL

12. **Synchronize catalog and deal catalog**: gpapi notifies Goods Product Catalog and Deal Catalog of the deactivation.
    - From: `continuumGpapiService`
    - To: Goods Product Catalog, Deal Catalog
    - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid category/taxonomy | Return 422 with taxonomy error | Product not created |
| Catalog sync failure | Return error; product state may be inconsistent | Requires manual reconciliation |
| Approval permission denied | Return 403 Forbidden | Status not changed |
| Deactivation of active deals | Return 422 with conflict error | Deactivation blocked until deals resolved |

## Sequence Diagram

```
VendorPortalUI -> continuumGpapiService: POST /api/v1/products (product data)
continuumGpapiService -> TaxonomyService: GET /categories/:id (validate)
TaxonomyService --> continuumGpapiService: 200 OK (category valid)
continuumGpapiService -> continuumGpapiDb: INSERT product (status: draft)
continuumGpapiService -> GoodsProductCatalog: POST (draft product)
GoodsProductCatalog --> continuumGpapiService: 200 OK
continuumGpapiService --> VendorPortalUI: 201 Created (product record)
```

## Related

- Architecture dynamic view: `dynamic-vendorOnboardingFlow`
- Related flows: [Item Master Management](item-master-management.md), [Promotion Management](promotion-management.md), [Contract Lifecycle](contract-lifecycle.md)
