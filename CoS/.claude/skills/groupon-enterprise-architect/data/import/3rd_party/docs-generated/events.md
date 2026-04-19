---
service: "online_booking_3rd_party"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

`online_booking_3rd_party` participates in the Groupon Message Bus (STOMP/JMS) as both a producer and a consumer. The Workers container (`continuumOnlineBooking3rdPartyWorkers`) handles all async messaging — consuming inbound events from the Appointment Engine and Booking Tool, then publishing normalized Booking Engine 3rd-party events after completing synchronization with external providers.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.BookingEngine.3rdParty.Events` | Mapping update event | Merchant place or service mapping created/updated/deleted | place_id, provider_id, mapping_id, status, timestamp |
| `jms.topic.BookingEngine.3rdParty.Events` | Provider sync event | Provider booking or availability synchronized from external system | place_id, reservation_id, availability_snapshot, sync_status, timestamp |

### Mapping Update Event Detail

- **Topic**: `jms.topic.BookingEngine.3rdParty.Events`
- **Trigger**: A merchant place or service mapping is created, updated, or deleted via the API or resolved through a worker sync cycle
- **Payload**: place_id, provider_id, mapping_id, event_type (created/updated/deleted), status, timestamp
- **Consumers**: Booking Engine downstream services (Availability Engine, Appointment Engine)
- **Guarantees**: at-least-once

### Provider Sync Event Detail

- **Topic**: `jms.topic.BookingEngine.3rdParty.Events`
- **Trigger**: Worker completes a synchronization cycle with an external provider following polling or inbound event processing
- **Payload**: place_id, reservation_id, availability_snapshot, sync_status, provider_ref, timestamp
- **Consumers**: Booking Engine downstream services
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `BookingEngine.AppointmentEngine.Events` | Appointment lifecycle event | `workerEventConsumers` | Triggers provider synchronization via `workerProviderSync` |
| `BookingTool.Services.BookingEngine` | Booking tool service event | `workerEventConsumers` | Triggers provider synchronization and state reconciliation |

### AppointmentEngine Event Detail

- **Topic**: `BookingEngine.AppointmentEngine.Events`
- **Handler**: `workerEventConsumers` transforms inbound event payloads into provider synchronization actions, delegating to `workerProviderSync`
- **Idempotency**: No explicit evidence — Resque retry semantics imply at-least-once processing
- **Error handling**: Resque retry with backoff; failed jobs remain in Resque queue for inspection
- **Processing order**: unordered

### BookingTool Event Detail

- **Topic**: `BookingTool.Services.BookingEngine`
- **Handler**: `workerEventConsumers` processes booking tool service events, triggering mapping reconciliation and provider sync
- **Idempotency**: No explicit evidence — Resque retry semantics imply at-least-once processing
- **Error handling**: Resque retry with backoff
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found — DLQ configuration not confirmed from inventory. Resque failed job queue serves as the de-facto failure store.
