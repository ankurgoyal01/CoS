---
service: "marketing"
title: "Order Confirmation Notification"
generated: "2026-03-03"
type: flow
flow_name: "order-confirmation-notification"
flow_type: synchronous
trigger: "Order completion in Orders Service"
participants:
  - "continuumOrdersService"
  - "continuumMarketingPlatform"
architecture_ref: "dynamic-continuum-orders-service"
---

# Order Confirmation Notification

## Summary

When a consumer completes an order, the Orders Service triggers a confirmation notification via the Marketing & Delivery Platform. This is part of the broader Orders Checkout & Fulfillment Flow where the Orders Service coordinates payment processing, voucher reservation, and then triggers the confirmation notification as the final step. The Marketing Platform delivers the confirmation to the consumer via the appropriate channel (email, push, inbox).

## Trigger

- **Type**: api-call
- **Source**: Orders Service after successful checkout and payment
- **Frequency**: Per order (on demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Orders Service | Initiates confirmation notification trigger after order completion | `continuumOrdersService` |
| Marketing & Delivery Platform | Receives trigger and delivers confirmation notification to consumer | `continuumMarketingPlatform` |

## Steps

1. **Order completed**: Orders Service completes payment authorization, capture, and voucher reservation.
   - From: `continuumOrdersService`
   - To: (internal order processing)
   - Protocol: Internal

2. **Trigger confirmation**: Orders Service calls Marketing Platform to trigger confirmation notification.
   - From: `continuumOrdersService`
   - To: `continuumMarketingPlatform`
   - Protocol: JSON/HTTPS

3. **Deliver notification**: Marketing Platform processes the trigger and delivers the confirmation to the consumer via the appropriate channel.
   - From: `continuumMarketingPlatform`
   - To: Consumer (email, push, or inbox)
   - Protocol: Channel-dependent

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Marketing Platform unavailable | > No evidence found in codebase. | Confirmation notification may be delayed; order is already complete |
| Invalid notification payload | > No evidence found in codebase. | Notification not delivered |

## Sequence Diagram

```
continuumOrdersService -> continuumMarketingPlatform: Trigger confirmation notification (JSON/HTTPS)
continuumMarketingPlatform -> Consumer: Deliver confirmation (email/push/inbox)
```

## Related

- Architecture dynamic view: `dynamic-continuum-orders-service`
- Architecture dynamic view: `dynamic-continuum-consumer-purchase-e2e`
- Related flows: [Campaign Notification Flow](campaign-notification-flow.md)
