---
service: "online_booking_3rd_party"
title: "Merchant Place Polling"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "merchant-place-polling"
flow_type: scheduled
trigger: "Resque scheduler cron job"
participants:
  - "continuumOnlineBooking3rdPartyWorkers"
  - "continuumOnlineBooking3rdPartyMysql"
  - "continuumOnlineBooking3rdPartyRedis"
  - "emeaBtos"
  - "continuumAvailabilityEngine"
  - "continuumAppointmentsEngine"
  - "messageBus"
architecture_ref: "dynamic-provider-workerProviderSync-from-inbound-event-flow"
---

# Merchant Place Polling

## Summary

The merchant place polling flow is a scheduled background process that proactively synchronizes reservations and availability between Groupon and third-party provider systems. The `workerPollingOrchestrator` queries MySQL for all merchant places with active, pollable mappings, enqueues per-place sync jobs, and `workerProviderSync` executes provider API calls to fetch and apply changes. After synchronization, `workerEventPublisher` emits domain events to the Booking Engine topic.

## Trigger

- **Type**: schedule
- **Source**: Resque scheduler (resque-scheduler / active_scheduler cron definition)
- **Frequency**: Periodic (interval defined in Resque scheduler config; exact cron not confirmed from inventory)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Polling Orchestrator | Queries pollable places and enqueues sync jobs | `continuumOnlineBooking3rdPartyWorkers` / `workerPollingOrchestrator` |
| Provider Sync Engine | Executes provider API calls and applies sync results | `continuumOnlineBooking3rdPartyWorkers` / `workerProviderSync` |
| Event Publisher | Publishes sync outcome events | `continuumOnlineBooking3rdPartyWorkers` / `workerEventPublisher` |
| MySQL | Source of pollable mappings; sync state destination | `continuumOnlineBooking3rdPartyMysql` |
| Redis | Resque job queue | `continuumOnlineBooking3rdPartyRedis` |
| Provider APIs | Source of booking and availability data | `emeaBtos` |
| Availability Engine | Receives synchronized availability state | `continuumAvailabilityEngine` |
| Appointments Engine | Receives synchronized reservation state | `continuumAppointmentsEngine` |
| Message Bus | Receives published 3rd-party domain events | `messageBus` |

## Steps

1. **Schedule Fires**: Resque scheduler triggers the polling orchestrator job on its defined cron interval
   - From: `resque-scheduler`
   - To: `continuumOnlineBooking3rdPartyWorkers` / `workerPollingOrchestrator`
   - Protocol: Resque job queue (Redis)

2. **Query Pollable Places**: Orchestrator queries MySQL for merchant places with active, poll-eligible mappings
   - From: `workerPollingOrchestrator`
   - To: `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

3. **Enqueue Sync Jobs**: For each pollable place, orchestrator enqueues a provider sync job in Resque
   - From: `workerPollingOrchestrator`
   - To: `continuumOnlineBooking3rdPartyRedis`
   - Protocol: Resque (Redis)

4. **Fetch Provider Data**: Provider sync engine calls the external provider API to retrieve updated bookings, services, and availability
   - From: `workerProviderSync`
   - To: `emeaBtos`
   - Protocol: HTTP/JSON

5. **Persist Sync State**: Updates reservations, service state, and sync progress in MySQL
   - From: `workerProviderSync`
   - To: `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

6. **Push Availability State**: Applies synchronized service and availability data to Availability Engine
   - From: `workerProviderSync`
   - To: `continuumAvailabilityEngine`
   - Protocol: HTTP/JSON

7. **Update Reservations**: Applies reservation lifecycle updates to Appointment Engine when required
   - From: `workerProviderSync`
   - To: `continuumAppointmentsEngine`
   - Protocol: HTTP/JSON

8. **Publish Domain Events**: Event publisher emits normalized 3rd-party sync events to `jms.topic.BookingEngine.3rdParty.Events`
   - From: `workerEventPublisher`
   - To: `messageBus`
   - Protocol: STOMP/JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Provider API unavailable | Resque job fails; automatic retry with backoff | Job enters Resque failed queue after max retries; sync deferred to next poll cycle |
| MySQL write failure | Job fails; Resque retry | Sync state not persisted; retried on next cycle |
| Availability Engine timeout | Job fails; Resque retry | Availability state not updated until retry succeeds |
| Event publish failure | Job fails; Resque retry | Downstream consumers do not receive event until retry succeeds |

## Sequence Diagram

```
workerPollingOrchestrator -> continuumOnlineBooking3rdPartyMysql: Query pollable merchant places
continuumOnlineBooking3rdPartyMysql --> workerPollingOrchestrator: Return list of pollable places
workerPollingOrchestrator -> continuumOnlineBooking3rdPartyRedis: Enqueue per-place sync jobs
workerProviderSync -> emeaBtos: Fetch provider bookings/availability/services
emeaBtos --> workerProviderSync: Return provider data
workerProviderSync -> continuumOnlineBooking3rdPartyMysql: Persist sync state and reservations
workerProviderSync -> continuumAvailabilityEngine: Push synchronized availability state
workerProviderSync -> continuumAppointmentsEngine: Apply reservation lifecycle updates
workerEventPublisher -> messageBus: Publish BookingEngine.3rdParty.Events
```

## Related

- Architecture dynamic view: `dynamic-provider-workerProviderSync-from-inbound-event-flow`
- Related flows: [Appointment Event Consumption](appointment-event-consumption.md), [Webhook Processing](webhook-processing.md)
