---
service: "orders-rails3"
title: "Refund and Cancellation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "refund-and-cancellation"
flow_type: asynchronous
trigger: "API call to update order/line item status, or daemon-scheduled delayed cancellation"
participants:
  - "continuumOrdersService"
  - "continuumOrdersWorkers"
  - "continuumOrdersDaemons"
  - "continuumPaymentsService"
  - "paymentGateways"
  - "continuumOrdersDb"
  - "continuumRedis"
  - "messageBus"
architecture_ref: "dynamic-continuum-orders-refund"
---

# Refund and Cancellation

## Summary

The refund and cancellation flow handles order and line item cancellations, returning funds to customers and releasing inventory. Cancellations can be immediate (triggered by API calls) or delayed (scheduled by the Orders Daemons for time-based expiry scenarios). Refunds are processed asynchronously by the Cancellation & Refund Workers, which interact with the Payments Service and payment gateways to issue credits, then update order state and publish events to the Message Bus.

## Trigger

- **Type**: api-call or schedule
- **Source**: Direct API call updating order/line item status to cancelled; or `continuumOrdersDaemons_retrySchedulers` triggering `order_line_item_delayed_cancellation` for expiry/exchange scenarios
- **Frequency**: On-demand (user-initiated) or scheduled (daemon-driven for delayed cancellations and expired exchanges)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Payments & Transactions API | Receives API cancellation request; enqueues refund job | `continuumOrdersApi_paymentsControllers` |
| Cancellation & Refund Workers | Executes refund processing, billing record deactivation | `continuumOrdersWorkers_cancellationWorkers` |
| Domain Utility Workers | Handles gift card refunds and expired exchange cancellations | `continuumOrdersWorkers_miscDomainWorkers` |
| Retry Schedulers | Schedules delayed cancellations and line item expiry | `continuumOrdersDaemons_retrySchedulers` |
| Payments Service | Manages refund authorization against billing records | `continuumPaymentsService` |
| Payment Gateways | Executes the actual refund transaction | `paymentGateways` |
| Orders DB | Updated with cancellation and refund state | `continuumOrdersDb` |
| Redis Cache/Queue | Hosts Resque queues for cancellation jobs | `continuumRedis` |
| Message Bus | Receives BillingRecordUpdate and OrderSnapshots events post-cancellation | `messageBus` |

## Steps

1. **Receives cancellation request**: API call or daemon schedule initiates cancellation.
   - From: `client` (API) or `continuumOrdersDaemons_retrySchedulers` (scheduled)
   - To: `continuumOrdersApi_paymentsControllers`
   - Protocol: REST (API path) or Resque (daemon path)

2. **Validates cancellation eligibility**: Checks order state, cancellation policy, and time-window constraints.
   - From: `continuumOrdersApi_paymentsControllers`
   - To: `continuumOrdersDb`
   - Protocol: ActiveRecord

3. **Enqueues refund/cancellation job**: Places async job for the appropriate cancellation worker onto Resque.
   - From: `continuumOrdersApi_paymentsControllers`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque enqueue)

4. **Dequeues and processes refund**: Cancellation worker fetches order/payment data and calls Payments Service to initiate refund.
   - From: `continuumOrdersWorkers_cancellationWorkers`
   - To: `continuumPaymentsService`
   - Protocol: REST

5. **Executes payment gateway refund**: Payments Service instructs the payment gateway to issue the refund credit.
   - From: `continuumPaymentsService`
   - To: `paymentGateways`
   - Protocol: REST

6. **Deactivates billing record** (if full cancellation): Marks the billing record as deactivated for PCI compliance.
   - From: `continuumOrdersWorkers_cancellationWorkers`
   - To: `continuumOrdersDb`
   - Protocol: ActiveRecord

7. **Updates order and line item state**: Sets order/line item status to `cancelled` and records refund amount.
   - From: `continuumOrdersWorkers_cancellationWorkers`
   - To: `continuumOrdersDb`
   - Protocol: ActiveRecord

8. **Publishes BillingRecordUpdate event**: Notifies downstream systems of billing record deactivation.
   - From: `continuumOrdersApi_messageBusPublishers`
   - To: `messageBus`
   - Protocol: Message Bus

9. **Publishes OrderSnapshots event**: Publishes updated order state (cancelled) to Message Bus.
   - From: `continuumOrdersApi_messageBusPublishers`
   - To: `messageBus`
   - Protocol: Message Bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Payments Service unavailable | Job fails; placed in Resque retry queue | Refund deferred; daemon retries; customer notified via separate notification flow |
| Payment gateway refund declined | Worker logs error; job retried | Refund job retried up to configured limit; escalated to manual processing if exhausted |
| Order already cancelled (idempotency) | Worker detects state; skips processing | No duplicate refund issued; logs idempotency event |
| Mass refund (bulk cancellation) | `order_line_item_mass_refund_worker` processes batch | Individual line items refunded sequentially; partial failures retried independently |

## Sequence Diagram

```
Client -> continuumOrdersService: PUT /orders/v1/orders/:id (cancel)
continuumOrdersService -> continuumOrdersDb: SELECT order + validate state
continuumOrdersDb --> continuumOrdersService: order record
continuumOrdersService -> continuumRedis: ENQUEUE order_delayed_cancellation_worker job
continuumOrdersService --> Client: HTTP 200 cancellation accepted
continuumOrdersWorkers_cancellationWorkers -> continuumRedis: DEQUEUE cancellation job
continuumOrdersWorkers_cancellationWorkers -> continuumPaymentsService: POST issue refund
continuumPaymentsService -> paymentGateways: refund transaction
paymentGateways --> continuumPaymentsService: refund confirmed
continuumPaymentsService --> continuumOrdersWorkers_cancellationWorkers: refund completed
continuumOrdersWorkers_cancellationWorkers -> continuumOrdersDb: UPDATE order status = cancelled
continuumOrdersWorkers_cancellationWorkers -> continuumOrdersDb: UPDATE billing_record status = deactivated
continuumOrdersWorkers_cancellationWorkers -> messageBus: PUBLISH BillingRecordUpdate
continuumOrdersWorkers_cancellationWorkers -> messageBus: PUBLISH OrderSnapshots
```

## Related

- Architecture dynamic view: `dynamic-continuum-orders-refund`
- Related flows: [Order Creation and Collection](order-creation-and-collection.md), [Daemon Retry and Maintenance](daemon-retry-maintenance.md)
