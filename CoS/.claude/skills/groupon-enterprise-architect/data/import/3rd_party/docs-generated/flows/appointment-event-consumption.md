---
service: "online_booking_3rd_party"
title: "Appointment Event Consumption"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "appointment-event-consumption"
flow_type: event-driven
trigger: "Message Bus — BookingEngine.AppointmentEngine.Events topic"
participants:
  - "continuumOnlineBooking3rdPartyWorkers"
  - "messageBus"
  - "continuumOnlineBooking3rdPartyMysql"
  - "emeaBtos"
  - "continuumAvailabilityEngine"
  - "continuumAppointmentsEngine"
architecture_ref: "dynamic-provider-workerProviderSync-from-inbound-event-flow"
---

# Appointment Event Consumption

## Summary

This flow handles events originating from the Appointment Engine and delivered over the Message Bus. When an appointment lifecycle event is received (e.g., reservation created, modified, or cancelled), the `workerEventConsumers` component transforms the payload into provider synchronization actions and delegates to `workerProviderSync`, which relays the relevant changes to the third-party provider via its API and then publishes a normalized Booking Engine event.

## Trigger

- **Type**: event
- **Source**: `BookingEngine.AppointmentEngine.Events` topic on the Message Bus (STOMP/JMS)
- **Frequency**: On-demand (event-driven, driven by Appointment Engine activity)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Event Consumers | Subscribes to topic and routes event to sync action | `continuumOnlineBooking3rdPartyWorkers` / `workerEventConsumers` |
| Provider Sync Engine | Executes provider API calls to relay changes | `continuumOnlineBooking3rdPartyWorkers` / `workerProviderSync` |
| Event Publisher | Publishes normalized outcome event | `continuumOnlineBooking3rdPartyWorkers` / `workerEventPublisher` |
| Message Bus | Source of inbound events; target for outbound events | `messageBus` |
| MySQL | Stores mapping and sync state | `continuumOnlineBooking3rdPartyMysql` |
| Provider APIs | Receives relayed reservation changes | `emeaBtos` |
| Availability Engine | Receives any availability state changes | `continuumAvailabilityEngine` |
| Appointments Engine | May receive confirmation updates | `continuumAppointmentsEngine` |

## Steps

1. **Consume Event**: `workerEventConsumers` receives an appointment lifecycle event from `BookingEngine.AppointmentEngine.Events`
   - From: `messageBus`
   - To: `continuumOnlineBooking3rdPartyWorkers` / `workerEventConsumers`
   - Protocol: STOMP/JMS

2. **Load Mapping State**: Queries MySQL to load the relevant merchant place mapping and provider configuration
   - From: `workerEventConsumers`
   - To: `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

3. **Transform to Sync Action**: Maps appointment event payload to provider-specific synchronization action
   - From: `workerEventConsumers`
   - To: `workerProviderSync`
   - Protocol: Direct (in-process)

4. **Call Provider API**: Relays the reservation change (create/modify/cancel) to the external provider system
   - From: `workerProviderSync`
   - To: `emeaBtos`
   - Protocol: HTTP/JSON

5. **Persist Sync Progress**: Updates sync state, reservation record, and retry metadata in MySQL
   - From: `workerProviderSync`
   - To: `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

6. **Apply Availability Updates**: Pushes any availability changes resulting from the reservation action to Availability Engine
   - From: `workerProviderSync`
   - To: `continuumAvailabilityEngine`
   - Protocol: HTTP/JSON

7. **Confirm Reservation Update**: Applies any required reservation confirmation back to Appointments Engine
   - From: `workerProviderSync`
   - To: `continuumAppointmentsEngine`
   - Protocol: HTTP/JSON

8. **Publish Outcome Event**: Emits normalized 3rd-party event to `jms.topic.BookingEngine.3rdParty.Events`
   - From: `workerEventPublisher`
   - To: `messageBus`
   - Protocol: STOMP/JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Provider API error | Resque job fails; automatic retry with backoff | Provider not updated until retry succeeds |
| Mapping not found | Job fails with error; enters Resque failed queue | Requires manual inspection |
| Appointments Engine timeout | Retry; confirmation delayed | Reservation state may be temporarily inconsistent |
| Message Bus disconnection | Resque consumer reconnects; at-least-once delivery | Events may be re-delivered |

## Sequence Diagram

```
messageBus -> workerEventConsumers: Deliver BookingEngine.AppointmentEngine.Events message
workerEventConsumers -> continuumOnlineBooking3rdPartyMysql: Load mapping and provider state
workerEventConsumers -> workerProviderSync: Dispatch sync action
workerProviderSync -> emeaBtos: Relay reservation change to provider
emeaBtos --> workerProviderSync: Provider confirmation
workerProviderSync -> continuumOnlineBooking3rdPartyMysql: Persist sync progress
workerProviderSync -> continuumAvailabilityEngine: Apply availability updates
workerProviderSync -> continuumAppointmentsEngine: Confirm reservation update
workerEventPublisher -> messageBus: Publish BookingEngine.3rdParty.Events
```

## Related

- Architecture dynamic view: `dynamic-provider-workerProviderSync-from-inbound-event-flow`
- Related flows: [Booking Tool Sync](booking-tool-sync.md), [Merchant Place Polling](merchant-place-polling.md)
