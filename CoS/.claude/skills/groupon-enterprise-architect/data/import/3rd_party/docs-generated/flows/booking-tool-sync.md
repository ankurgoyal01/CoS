---
service: "online_booking_3rd_party"
title: "Booking Tool Sync"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "booking-tool-sync"
flow_type: event-driven
trigger: "Message Bus — BookingTool.Services.BookingEngine topic"
participants:
  - "continuumOnlineBooking3rdPartyWorkers"
  - "messageBus"
  - "continuumOnlineBooking3rdPartyMysql"
  - "emeaBtos"
  - "continuumAvailabilityEngine"
  - "continuumAppointmentsEngine"
architecture_ref: "dynamic-provider-workerProviderSync-from-inbound-event-flow"
---

# Booking Tool Sync

## Summary

This flow processes service events emitted by the Merchant Booking Tool onto the `BookingTool.Services.BookingEngine` topic. These events represent service-level changes in the Booking Tool (e.g., service configuration changes, booking actions taken by a merchant). The worker layer consumes these events, reconciles affected merchant-place mapping state in MySQL, and delegates to `workerProviderSync` to apply any required updates to the third-party provider system.

## Trigger

- **Type**: event
- **Source**: `BookingTool.Services.BookingEngine` topic on the Message Bus (STOMP/JMS)
- **Frequency**: On-demand (event-driven, driven by Merchant Booking Tool activity)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Event Consumers | Subscribes to topic and routes event to sync action | `continuumOnlineBooking3rdPartyWorkers` / `workerEventConsumers` |
| Provider Sync Engine | Applies mapping and provider-state reconciliation | `continuumOnlineBooking3rdPartyWorkers` / `workerProviderSync` |
| Event Publisher | Publishes normalized outcome events | `continuumOnlineBooking3rdPartyWorkers` / `workerEventPublisher` |
| Message Bus | Source of Booking Tool events; target for 3rd-party events | `messageBus` |
| MySQL | Stores mapping and reconciliation state | `continuumOnlineBooking3rdPartyMysql` |
| Provider APIs | Receives relayed service/booking changes | `emeaBtos` |
| Availability Engine | Receives any availability state updates | `continuumAvailabilityEngine` |
| Appointments Engine | Receives reservation updates if required | `continuumAppointmentsEngine` |

## Steps

1. **Consume Event**: `workerEventConsumers` receives a service event from `BookingTool.Services.BookingEngine`
   - From: `messageBus`
   - To: `continuumOnlineBooking3rdPartyWorkers` / `workerEventConsumers`
   - Protocol: STOMP/JMS

2. **Load Mapping State**: Queries MySQL to load affected merchant place mapping and current sync state
   - From: `workerEventConsumers`
   - To: `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

3. **Reconcile Mapping**: Transforms Booking Tool event into provider-compatible sync action via `workerProviderSync`
   - From: `workerEventConsumers`
   - To: `workerProviderSync`
   - Protocol: Direct (in-process)

4. **Apply Provider Update**: Relays the service or booking change to the external provider API
   - From: `workerProviderSync`
   - To: `emeaBtos`
   - Protocol: HTTP/JSON

5. **Persist Reconciliation State**: Writes updated mapping and sync state back to MySQL
   - From: `workerProviderSync`
   - To: `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

6. **Push Availability Updates** (if applicable): Applies availability changes to Availability Engine
   - From: `workerProviderSync`
   - To: `continuumAvailabilityEngine`
   - Protocol: HTTP/JSON

7. **Update Reservation** (if applicable): Applies reservation lifecycle update to Appointments Engine
   - From: `workerProviderSync`
   - To: `continuumAppointmentsEngine`
   - Protocol: HTTP/JSON

8. **Publish Domain Event**: Emits normalized event to `jms.topic.BookingEngine.3rdParty.Events`
   - From: `workerEventPublisher`
   - To: `messageBus`
   - Protocol: STOMP/JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Provider API failure | Resque retry with backoff | Provider not updated until retry; mapping state may be temporarily stale |
| No mapping found for Booking Tool event | Job logged and discarded or sent to failed queue | Requires investigation |
| Availability Engine timeout | Retry; availability state update deferred | Downstream consumers see stale availability temporarily |

## Sequence Diagram

```
messageBus -> workerEventConsumers: Deliver BookingTool.Services.BookingEngine message
workerEventConsumers -> continuumOnlineBooking3rdPartyMysql: Load mapping and sync state
workerEventConsumers -> workerProviderSync: Dispatch reconciliation action
workerProviderSync -> emeaBtos: Apply service/booking update to provider
emeaBtos --> workerProviderSync: Provider response
workerProviderSync -> continuumOnlineBooking3rdPartyMysql: Persist reconciliation state
workerProviderSync -> continuumAvailabilityEngine: Push availability updates
workerProviderSync -> continuumAppointmentsEngine: Apply reservation update (if applicable)
workerEventPublisher -> messageBus: Publish BookingEngine.3rdParty.Events
```

## Related

- Architecture dynamic view: `dynamic-provider-workerProviderSync-from-inbound-event-flow`
- Related flows: [Appointment Event Consumption](appointment-event-consumption.md), [Merchant Place Polling](merchant-place-polling.md)
