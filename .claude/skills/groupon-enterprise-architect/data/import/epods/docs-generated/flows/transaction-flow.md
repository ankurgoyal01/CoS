---
service: "epods"
title: "Transaction Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "transaction-flow"
flow_type: event-driven
trigger: "VoucherMessageHandler event consumed from message bus"
participants:
  - "messageBus"
  - "continuumEpodsService"
  - "continuumEpodsPostgres"
  - "continuumEpodsRedis"
  - "mindbodyApi"
  - "bookerApi"
  - "continuumOrdersService"
  - "continuumCfsService"
architecture_ref: "dynamic-epods-transaction"
---

# Transaction Flow

## Summary

The Transaction Flow processes voucher lifecycle events received from the Groupon message bus. When a voucher is redeemed or requires cancellation, EPODS receives the event via `VoucherMessageHandler`, resolves the associated booking and partner, calls the partner system to confirm or cancel the redemption, updates the booking state in PostgreSQL, and publishes a `VoucherRedemption` event back to the message bus for downstream consumption by Orders and CFS.

## Trigger

- **Type**: event
- **Source**: Groupon message bus (`messageBus`) — `VoucherMessageHandler` event
- **Frequency**: Per voucher lifecycle action (redemption or cancellation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Source of inbound VoucherMessageHandler events | `messageBus` |
| EPODS Service | Consumes voucher events; coordinates partner redemption; publishes VoucherRedemption | `continuumEpodsService` |
| EPODS Postgres | Resolves booking and mapping records; records voucher/redemption state | `continuumEpodsPostgres` |
| EPODS Redis | Distributed lock during voucher state update | `continuumEpodsRedis` |
| MindBody API | Partner system receiving voucher redemption confirmation | `mindbodyApi` |
| Booker API | Partner system receiving voucher redemption confirmation | `bookerApi` |
| Orders Service | Downstream consumer of VoucherRedemption event; updates order state | `continuumOrdersService` |
| CFS | Downstream consumer of VoucherRedemption event; updates custom fields | `continuumCfsService` |

## Steps

1. **Consume VoucherMessageHandler event**: EPODS's message bus consumer receives a `VoucherMessageHandler` event containing voucherId, bookingId, action (redeem/cancel), and consumer details.
   - From: `messageBus`
   - To: `continuumEpodsService`
   - Protocol: JMS/STOMP

2. **Resolve booking and partner mapping**: EPODS queries `continuumEpodsPostgres` to load the booking record and resolve the partner-system booking ID.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

3. **Check idempotency**: EPODS verifies the voucher has not already been processed (checks existing redemption state in `continuumEpodsPostgres`). If already processed, flow terminates with a no-op.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

4. **Acquire transaction lock**: EPODS acquires a Redis lock on the voucher/booking record to prevent concurrent redemption processing.
   - From: `continuumEpodsService`
   - To: `continuumEpodsRedis`
   - Protocol: Redis

5. **Fetch custom fields**: EPODS calls CFS to retrieve any custom field values needed for the partner redemption payload.
   - From: `continuumEpodsService`
   - To: `continuumCfsService`
   - Protocol: REST

6. **Notify partner of redemption**: EPODS calls the target partner API (MindBody or Booker) to confirm the voucher redemption or process the cancellation against the partner booking.
   - From: `continuumEpodsService`
   - To: `mindbodyApi` or `bookerApi`
   - Protocol: REST

7. **Update redemption state**: EPODS writes the redemption result (confirmed, failed, cancelled) to `continuumEpodsPostgres`.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

8. **Release transaction lock**: EPODS releases the Redis lock.
   - From: `continuumEpodsService`
   - To: `continuumEpodsRedis`
   - Protocol: Redis

9. **Publish VoucherRedemption event**: EPODS publishes a `VoucherRedemption` event to the message bus containing voucherId, bookingId, redemptionTime, and partnerId.
   - From: `continuumEpodsService`
   - To: `messageBus`
   - Protocol: JMS/STOMP

10. **Downstream consumers react**: Orders Service and CFS consume the `VoucherRedemption` event and update their own state (order fulfillment, custom field update).
    - From: `messageBus`
    - To: `continuumOrdersService`, `continuumCfsService`
    - Protocol: JMS/STOMP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Partner API redemption failure | `failsafe` retry with backoff; mark redemption as failed in PostgreSQL | Voucher redemption fails; event not published; message retried via DLQ |
| Duplicate voucher event (already redeemed) | Idempotency check at step 3 detects duplicate; flow exits as no-op | No partner call made; no duplicate event published |
| Lock contention (concurrent redemption) | Lock acquisition fails; event requeued for retry | Retry on next dequeue attempt |
| CFS call failure | Log and proceed without custom fields if non-critical; fail if required | Partner call may proceed with reduced payload; log degradation |
| Message bus publish failure | Retry via `jtier-messagebus-client` | Redemption state persisted; downstream notification delayed |
| Booking not found for voucherId | Log error; dead-letter the event | Manual investigation required; no partner call made |

## Sequence Diagram

```
MessageBus -> EPODS: Consume VoucherMessageHandler (voucherId, bookingId, action)
EPODS -> EpodsPostgres: Resolve booking and partner mapping
EPODS -> EpodsPostgres: Idempotency check (already redeemed?)
EPODS -> EpodsRedis: Acquire transaction lock
EPODS -> CfsService: Fetch custom fields
EPODS -> PartnerAPI (MindBody/Booker): Confirm redemption / cancellation
PartnerAPI --> EPODS: Redemption confirmation
EPODS -> EpodsPostgres: Write redemption state
EPODS -> EpodsRedis: Release lock
EPODS -> MessageBus: Publish VoucherRedemption event
MessageBus -> OrdersService: Consume VoucherRedemption
MessageBus -> CfsService: Consume VoucherRedemption
```

## Related

- Architecture dynamic view: `dynamic-epods-transaction`
- Related flows: [Booking Flow](booking-flow.md), [Webhook Processing Flow](webhook-processing-flow.md)
