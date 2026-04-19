---
service: "channel-manager-integrator-derbysoft"
title: "Reservation Processing"
generated: "2026-03-03"
type: flow
flow_name: "reservation-processing"
flow_type: asynchronous
trigger: "MBus RESERVE message from Groupon Inventory Service Worker"
participants:
  - "continuumMbusBroker"
  - "continuumChannelManagerIntegratorDerbysoftApp"
  - "continuumChannelManagerIntegratorDerbysoftDb"
  - "derbysoftCmApi"
architecture_ref: "dynamic-ReservationProcessingFlow"
---

# Reservation Processing

## Summary

When the Groupon Inventory Service Worker (ISW) needs to book a hotel stay through the Derbysoft channel manager, it publishes a `RequestMessageContainer` of type `RESERVE` to the MBus broker. This service consumes the message, runs a two-step state machine (prebook then book) against the Derbysoft API, persists each state transition, and publishes the booking outcome (success or failure) back to ISW via MBus as a `ResponseMessageContainer`.

## Trigger

- **Type**: event (MBus message)
- **Source**: Groupon Inventory Service Worker publishes `RequestMessageContainer` (type: `RESERVE`) to the MBus destination configured via `iswBookingMessageListenerConfig.destination`
- **Frequency**: Per booking request (on demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus Broker (ISW queue) | Delivers `RESERVE` message to this service | `continuumMbusBroker` |
| Messaging Adapter (`messagingAdapter_ChaManIntD`) | Consumes the MBus message and dispatches to the Reservation Workflow | `continuumChannelManagerIntegratorDerbysoftApp` |
| Reservation Workflow Service (`reservationWorkflowChaManInt`) | Runs the prebook → book state machine | `continuumChannelManagerIntegratorDerbysoftApp` |
| External Integration Clients (`outboundClients`) | Submits prebook and book HTTP requests to Derbysoft | `continuumChannelManagerIntegratorDerbysoftApp` |
| Persistence Adapter (`persistenceAdapterChaManInt`) | Records reservation state at each step | `continuumChannelManagerIntegratorDerbysoftDb` |
| MBus Broker (CMI response queue) | Delivers booking outcome back to ISW | `continuumMbusBroker` |
| Derbysoft Channel Manager API | Processes prebook and book requests | external |

## Steps

1. **Receive RESERVE message**: `IswBookingMessageProcessor` reads a `RequestMessageContainer` (type: `RESERVE`) from MBus via `MbusReader`; extracts `xRequestId` and inner `ReserveRequestMessage` payload.
   - From: `continuumMbusBroker`
   - To: `messagingAdapter_ChaManIntD`
   - Protocol: STOMP/JMS (MBus)

2. **Initialize reservation state**: `ReservationInitProcessor` creates a new reservation record in the database with state `RESERVATION_INIT`; builds prebook request payload from hotel, room-type, and rate-plan mapping data.
   - From: `reservationWorkflowChaManInt`
   - To: `persistenceAdapterChaManInt`
   - Protocol: JDBI/PostgreSQL

3. **Submit prebook to Derbysoft**: `DerbysoftReservationService` calls `POST reservation/prebook` via `DerbysoftClient`; passes `PreBookRequest` including hotel, room-type, rate, and guest details.
   - From: `outboundClients`
   - To: Derbysoft Channel Manager API
   - Protocol: HTTPS/JSON

4. **Persist prebook outcome**: Stores prebook request and response records; transitions reservation state to `PRE_BOOK_SUCCEED` or `PRE_BOOK_FAILED`.
   - From: `reservationWorkflowChaManInt`
   - To: `persistenceAdapterChaManInt`
   - Protocol: JDBI/PostgreSQL

5. **Submit book to Derbysoft** (if prebook succeeded): `PrebookSuccessProcessor` calls `POST reservation/book` via `DerbysoftClient`; passes `BookRequest` with the prebook reference.
   - From: `outboundClients`
   - To: Derbysoft Channel Manager API
   - Protocol: HTTPS/JSON

6. **Persist book outcome**: Stores book request and response records; transitions reservation state to `BOOK_SUCCEED` or `BOOK_FAILED`; parses reservation detail from Derbysoft response.
   - From: `reservationWorkflowChaManInt`
   - To: `persistenceAdapterChaManInt`
   - Protocol: JDBI/PostgreSQL

7. **Emit booking outcome event**: `messagingAdapter_ChaManIntD` wraps the `AbstractResponseMessage` (success or failure) in a `ResponseMessageContainer` and sends it to the MBus CMI response destination; acknowledges the original `RESERVE` message.
   - From: `messagingAdapter_ChaManIntD`
   - To: `continuumMbusBroker`
   - Protocol: STOMP/JMS (MBus)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Derbysoft prebook fails (non-recoverable response) | `PrebookFailedProcessor` sets state to `PRE_BOOK_FAILED`; emits failure `ResponseMessageContainer` | ISW notified of booking failure; message acked |
| Derbysoft book fails (non-recoverable response) | `BookFailedProcessor` sets state to `BOOK_FAILED`; emits failure `ResponseMessageContainer` | ISW notified of booking failure; message acked |
| `RecoverableExecutionException` thrown | MBus message nacked; re-queued for retry | Message retried; eventually lands in DLQ if retry exhausted |
| `MessageException` (MBus send failure) | Logged; message nacked | Message retried; DLQ if persistent |
| Generic `Exception` | Logged; message nacked | Message retried; DLQ if persistent |
| DLQ accumulation | `DLQMessageProcessor` handles terminal failure | See [DLQ Processing](dlq-processing.md) |

## Sequence Diagram

```
ISW (MBus) -> messagingAdapter_ChaManIntD: RESERVE RequestMessageContainer
messagingAdapter_ChaManIntD -> reservationWorkflowChaManInt: dispatch ReserveRequestMessage
reservationWorkflowChaManInt -> persistenceAdapterChaManInt: create reservation (RESERVATION_INIT)
reservationWorkflowChaManInt -> outboundClients: POST reservation/prebook
outboundClients -> DerbysoftAPI: PreBookRequest (HTTPS)
DerbysoftAPI --> outboundClients: PreBookSuccessResponse / FailureResponse
reservationWorkflowChaManInt -> persistenceAdapterChaManInt: update state (PRE_BOOK_SUCCEED/FAILED)
reservationWorkflowChaManInt -> outboundClients: POST reservation/book [if prebook succeeded]
outboundClients -> DerbysoftAPI: BookRequest (HTTPS)
DerbysoftAPI --> outboundClients: BookSuccessResponse / FailureResponse
reservationWorkflowChaManInt -> persistenceAdapterChaManInt: update state (BOOK_SUCCEED/FAILED)
messagingAdapter_ChaManIntD -> ISW (MBus): ResponseMessageContainer (success or failure)
```

## Related

- Architecture dynamic view: `dynamic-ReservationProcessingFlow`
- Related flows: [Cancellation Processing](cancellation-processing.md), [DLQ Processing](dlq-processing.md)
- [Events](../events.md), [Integrations](../integrations.md)
