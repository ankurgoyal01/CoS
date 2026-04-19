---
service: "gpapi"
title: "Promotion Management"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "promotion-management"
flow_type: synchronous
trigger: "Vendor submits a promotion or co-op agreement request via Vendor Portal"
participants:
  - "continuumGpapiService"
  - "continuumGpapiDb"
  - "continuumGoodsPromotionManager"
architecture_ref: "dynamic-vendorOnboardingFlow"
---

# Promotion Management

## Summary

The promotion management flow handles the creation and maintenance of vendor promotions and co-op advertising agreements through gpapi. gpapi acts as a proxy and coordinator between the Vendor Portal and the Goods Promotion Manager service, which owns the promotion business logic. Co-op agreements represent cooperative advertising arrangements between Groupon and vendors; both promotions and co-op agreements share the same orchestration pattern through this flow.

## Trigger

- **Type**: api-call
- **Source**: Vendor submitting a promotion create/update or co-op agreement action via Vendor Portal UI
- **Frequency**: On demand (per promotion or co-op agreement action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Goods Vendor Portal UI | Initiates promotion and co-op agreement actions | — |
| Goods Product API | Proxies and validates requests; coordinates with Goods Promotion Manager | `continuumGpapiService` |
| gpapi Database | Stores local promotion reference records | `continuumGpapiDb` |
| Goods Promotion Manager | Owns promotion business logic and state | `continuumGoodsPromotionManager` |

## Steps

### Create Promotion

1. **Receive promotion request**: Vendor Portal UI submits a new promotion payload.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `POST /api/v2/promotions`
   - Protocol: REST

2. **Validate promotion data**: gpapi validates vendor context and promotion parameters.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb` (validate vendor context)
   - Protocol: PostgreSQL

3. **Forward to Goods Promotion Manager**: gpapi proxies the creation request to Goods Promotion Manager.
   - From: `continuumGpapiService`
   - To: `continuumGoodsPromotionManager` (create promotion)
   - Protocol: REST

4. **Store promotion reference**: gpapi persists a local reference to the created promotion.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

5. **Return promotion result**: gpapi returns the promotion record to the Vendor Portal UI.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 201 Created)

### Create Co-op Agreement

6. **Receive co-op request**: Vendor Portal UI submits a new co-op agreement payload.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `POST /api/v2/co_op_agreements`
   - Protocol: REST

7. **Validate and forward**: gpapi validates the request and forwards to Goods Promotion Manager.
   - From: `continuumGpapiService`
   - To: `continuumGoodsPromotionManager` (create co-op agreement)
   - Protocol: REST

8. **Return co-op agreement result**: gpapi returns the agreement record.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 201 Created)

### Update Promotion or Co-op Agreement

9. **Receive update request**: Vendor Portal UI submits changes to an existing promotion or co-op agreement.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `PATCH /api/v2/promotions/:id` or `PATCH /api/v2/co_op_agreements/:id`
   - Protocol: REST

10. **Proxy update to Goods Promotion Manager**: gpapi forwards the update.
    - From: `continuumGpapiService`
    - To: `continuumGoodsPromotionManager`
    - Protocol: REST

11. **Return updated record**: gpapi returns the updated promotion or co-op agreement.
    - From: `continuumGpapiService`
    - To: Goods Vendor Portal UI
    - Protocol: REST (HTTP 200 OK)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Goods Promotion Manager unavailable | Return 503 or error | Promotion not created/updated |
| Invalid promotion parameters | Return 422 Unprocessable Entity | Promotion not created |
| Co-op agreement conflict | Return 422 with conflict details | Agreement not created |

## Sequence Diagram

```
VendorPortalUI -> continuumGpapiService: POST /api/v2/promotions (promotion data)
continuumGpapiService -> continuumGpapiDb: validate vendor context
continuumGpapiDb --> continuumGpapiService: vendor valid
continuumGpapiService -> continuumGoodsPromotionManager: POST (create promotion)
continuumGoodsPromotionManager --> continuumGpapiService: 201 Created (promotion_id)
continuumGpapiService -> continuumGpapiDb: INSERT promotion reference
continuumGpapiService --> VendorPortalUI: 201 Created (promotion record)
```

## Related

- Architecture dynamic view: `dynamic-vendorOnboardingFlow`
- Related flows: [Contract Lifecycle](contract-lifecycle.md), [Product Lifecycle](product-lifecycle.md)
