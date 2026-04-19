---
service: "epods"
title: "Booking Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "booking-flow"
flow_type: synchronous
trigger: "API call from an internal Groupon service (e.g., Booking Tool or Orders)"
participants:
  - "bookingToolService"
  - "continuumEpodsService"
  - "continuumEpodsPostgres"
  - "continuumEpodsRedis"
  - "mindbodyApi"
  - "bookerApi"
  - "continuumCalendarService"
  - "continuumOrdersService"
  - "messageBus"
architecture_ref: "dynamic-epods-booking"
---

# Booking Flow

## Summary

The Booking Flow covers the complete lifecycle of a partner-backed booking: creation, retrieval, and cancellation. An internal Groupon consumer (typically the Booking Tool) calls EPODS with a Groupon-domain request; EPODS resolves the entity mapping, translates the request into the target partner's API format, calls the partner system, persists the result, and returns a normalized response. On status change, EPODS publishes a `BookingStatusChange` event to the message bus.

## Trigger

- **Type**: api-call
- **Source**: Booking Tool (`bookingToolService`) or Orders Service (`continuumOrdersService`)
- **Frequency**: On-demand, per user booking action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Booking Tool | Initiates booking create/cancel/get requests | `bookingToolService` |
| EPODS Service | Translation layer; mapping resolution; partner API orchestration | `continuumEpodsService` |
| EPODS Postgres | Stores booking records and entity mappings | `continuumEpodsPostgres` |
| EPODS Redis | Distributed lock acquisition during booking creation | `continuumEpodsRedis` |
| MindBody API | Target partner system for MindBody-backed bookings | `mindbodyApi` |
| Booker API | Target partner system for Booker-backed bookings | `bookerApi` |
| Calendar Service | Syncs the booking slot into the Groupon calendar | `continuumCalendarService` |
| Orders Service | Reads order context; receives booking status notifications | `continuumOrdersService` |
| Message Bus | Receives `BookingStatusChange` event after booking creation or cancellation | `messageBus` |

## Steps

### Create Booking

1. **Receive booking request**: Booking Tool sends `POST /v1/booking` to EPODS with Groupon deal ID, unit ID, consumer details, and slot information.
   - From: `bookingToolService`
   - To: `continuumEpodsService`
   - Protocol: REST

2. **Resolve entity mapping**: EPODS queries the mapping store to translate Groupon deal/unit/merchant IDs into partner-system identifiers.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

3. **Acquire distributed lock**: EPODS acquires a Redis lock keyed on the partner booking slot to prevent duplicate booking creation.
   - From: `continuumEpodsService`
   - To: `continuumEpodsRedis`
   - Protocol: Redis

4. **Retrieve partner configuration**: EPODS fetches partner-specific configuration (auth, endpoint overrides) from Partner Service.
   - From: `continuumEpodsService`
   - To: `continuumPartnerService`
   - Protocol: REST

5. **Translate and submit booking to partner**: EPODS builds the partner-specific booking payload and submits to the target partner API (MindBody or Booker).
   - From: `continuumEpodsService`
   - To: `mindbodyApi` or `bookerApi`
   - Protocol: REST

6. **Persist booking record**: EPODS writes the confirmed booking (including partner-assigned booking ID) to `continuumEpodsPostgres`.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

7. **Release distributed lock**: EPODS releases the Redis lock acquired in step 3.
   - From: `continuumEpodsService`
   - To: `continuumEpodsRedis`
   - Protocol: Redis

8. **Sync booking to calendar**: EPODS notifies Calendar Service of the confirmed booking slot.
   - From: `continuumEpodsService`
   - To: `continuumCalendarService`
   - Protocol: REST

9. **Publish BookingStatusChange event**: EPODS publishes a `BookingStatusChange` event to the message bus with status `CONFIRMED`.
   - From: `continuumEpodsService`
   - To: `messageBus`
   - Protocol: JMS/STOMP

10. **Return normalized response**: EPODS returns the confirmed booking in Groupon domain format to the caller.
    - From: `continuumEpodsService`
    - To: `bookingToolService`
    - Protocol: REST

### Cancel Booking

1. **Receive cancellation request**: Caller sends `DELETE /v1/booking/{id}` to EPODS.
   - From: `bookingToolService` or `continuumOrdersService`
   - To: `continuumEpodsService`
   - Protocol: REST

2. **Resolve booking and mapping**: EPODS loads the booking record and partner booking ID from `continuumEpodsPostgres`.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

3. **Submit cancellation to partner**: EPODS calls the partner API to cancel the booking.
   - From: `continuumEpodsService`
   - To: `mindbodyApi` or `bookerApi`
   - Protocol: REST

4. **Update booking record**: EPODS updates the booking status to `CANCELLED` in `continuumEpodsPostgres`.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

5. **Publish BookingStatusChange event**: EPODS publishes a `BookingStatusChange` event with status `CANCELLED`.
   - From: `continuumEpodsService`
   - To: `messageBus`
   - Protocol: JMS/STOMP

6. **Return cancellation confirmation**: EPODS returns success to the caller.
   - From: `continuumEpodsService`
   - To: `bookingToolService` or `continuumOrdersService`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Partner API unavailable | `failsafe` circuit breaker + retry with exponential backoff | Booking fails with 503; lock released; no record persisted |
| Entity mapping not found | Return 404 to caller | Booking rejected; no partner call made |
| Duplicate booking attempt (lock held) | Lock contention detected via Redis; request rejected | 409 Conflict returned to caller |
| Partner returns booking failure | Error translated and returned | 422 or 500 returned to caller; no record persisted |
| Calendar sync failure | Logged and retried asynchronously; booking still confirmed | Booking persisted; calendar may be temporarily inconsistent |
| Message bus publish failure | Logged; retry via `jtier-messagebus-client` | Booking persisted; downstream consumers may receive delayed event |

## Sequence Diagram

```
BookingTool -> EPODS: POST /v1/booking
EPODS -> EpodsPostgres: Resolve entity mapping
EPODS -> EpodsRedis: Acquire distributed lock
EPODS -> PartnerService: Fetch partner configuration
EPODS -> PartnerAPI (MindBody/Booker): Submit booking
PartnerAPI --> EPODS: Booking confirmation
EPODS -> EpodsPostgres: Persist booking record
EPODS -> EpodsRedis: Release lock
EPODS -> CalendarService: Sync booking slot
EPODS -> MessageBus: Publish BookingStatusChange (CONFIRMED)
EPODS --> BookingTool: 201 Created (normalized booking)
```

## Related

- Architecture dynamic view: `dynamic-epods-booking`
- Related flows: [Webhook Processing Flow](webhook-processing-flow.md), [Transaction Flow](transaction-flow.md), [Mapping Lifecycle Flow](mapping-lifecycle-flow.md)
