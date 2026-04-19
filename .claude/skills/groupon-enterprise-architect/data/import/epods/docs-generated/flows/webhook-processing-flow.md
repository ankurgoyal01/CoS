---
service: "epods"
title: "Webhook Processing Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "webhook-processing-flow"
flow_type: event-driven
trigger: "Inbound HTTP POST from a partner system to /webhook/*"
participants:
  - "mindbodyApi"
  - "squareApi"
  - "shopifyApi"
  - "continuumEpodsService"
  - "continuumEpodsPostgres"
  - "continuumEpodsRedis"
  - "messageBus"
  - "continuumOrdersService"
architecture_ref: "dynamic-epods-webhook"
---

# Webhook Processing Flow

## Summary

The Webhook Processing Flow handles inbound event notifications sent by partner systems to EPODS at the `/webhook/*` endpoint path. Partners such as MindBody, Square, and Shopify push event payloads when bookings are created, modified, cancelled, or when availability changes. EPODS validates the incoming request, translates the partner-specific payload into the Groupon domain model, updates internal state, and publishes the appropriate event to the message bus for downstream consumers.

## Trigger

- **Type**: event (inbound HTTP push from partner)
- **Source**: Partner system (MindBody confirmed; Square and Shopify via stub integrations)
- **Frequency**: Per partner event; on-demand based on partner activity

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MindBody API | Sends inbound booking and availability change webhooks | `mindbodyApi` |
| Square API | Sends inbound booking/order webhooks (stub — planned integration) | `squareApi` |
| Shopify API | Sends inbound order/commerce webhooks (stub — planned integration) | `shopifyApi` |
| EPODS Service | Receives, validates, translates, and routes webhook payloads | `continuumEpodsService` |
| EPODS Postgres | Reads existing booking/mapping records; writes updated booking status | `continuumEpodsPostgres` |
| EPODS Redis | Acquires lock during state updates to prevent race conditions | `continuumEpodsRedis` |
| Message Bus | Receives translated events (BookingStatusChange, AvailabilityUpdate) | `messageBus` |
| Orders Service | Downstream consumer of BookingStatusChange events via message bus | `continuumOrdersService` |

## Steps

1. **Receive partner webhook**: Partner system POSTs an event payload to `POST /webhook/{partner-type}` on EPODS.
   - From: `mindbodyApi` (or `squareApi` / `shopifyApi`)
   - To: `continuumEpodsService`
   - Protocol: REST (HTTP POST)

2. **Validate webhook signature**: EPODS verifies the HMAC or API-key signature on the inbound request to authenticate the partner source.
   - From: `continuumEpodsService`
   - To: `continuumEpodsService` (internal validation)
   - Protocol: direct

3. **Parse and classify event**: EPODS parses the partner-specific payload and determines the event type (booking status change, availability update, cancellation).
   - From: `continuumEpodsService`
   - To: `continuumEpodsService` (internal)
   - Protocol: direct

4. **Resolve mapping from partner IDs**: EPODS queries `continuumEpodsPostgres` to translate partner entity IDs (booking ID, product ID) to Groupon IDs.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

5. **Acquire update lock**: For booking status changes, EPODS acquires a Redis lock on the booking record to prevent concurrent updates.
   - From: `continuumEpodsService`
   - To: `continuumEpodsRedis`
   - Protocol: Redis

6. **Update internal state**: EPODS writes the updated booking status or availability data to `continuumEpodsPostgres`.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

7. **Release update lock**: EPODS releases the Redis lock.
   - From: `continuumEpodsService`
   - To: `continuumEpodsRedis`
   - Protocol: Redis

8. **Publish translated event**: EPODS publishes a `BookingStatusChange` or `AvailabilityUpdate` event to the message bus.
   - From: `continuumEpodsService`
   - To: `messageBus`
   - Protocol: JMS/STOMP

9. **Return acknowledgement to partner**: EPODS returns HTTP 200 to the partner to acknowledge receipt.
   - From: `continuumEpodsService`
   - To: `mindbodyApi` (or other partner)
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Signature validation failure | Reject with HTTP 401; log for investigation | Webhook payload discarded; partner will retry |
| Mapping not found for partner entity | Log warning; acknowledge to partner (HTTP 200) to prevent retry storms | Event not propagated; requires manual mapping fix |
| Database write failure | Log error; return HTTP 500 to partner | Partner retries; idempotency key prevents duplicate state updates |
| Message bus publish failure | Retry via `jtier-messagebus-client`; log on exhaustion | State persisted; downstream event delayed |
| Duplicate webhook (idempotency) | Check existing booking status before update; skip if already at target state | No-op; HTTP 200 returned to partner |

## Sequence Diagram

```
PartnerSystem -> EPODS: POST /webhook/{partner-type} (signed payload)
EPODS -> EPODS: Validate HMAC/signature
EPODS -> EPODS: Parse and classify event type
EPODS -> EpodsPostgres: Resolve partner ID mappings
EPODS -> EpodsRedis: Acquire update lock
EPODS -> EpodsPostgres: Write updated booking/availability state
EPODS -> EpodsRedis: Release lock
EPODS -> MessageBus: Publish BookingStatusChange or AvailabilityUpdate
EPODS --> PartnerSystem: HTTP 200 (acknowledged)
MessageBus -> OrdersService: Consume BookingStatusChange
```

## Related

- Architecture dynamic view: `dynamic-epods-webhook`
- Related flows: [Booking Flow](booking-flow.md), [Availability Sync Flow](availability-sync-flow.md)
