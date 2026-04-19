---
service: "calendar-service"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Calendar Service participates in asynchronous messaging via **MBus** (`availabilityEngineEventsBus`). The `messageBusAdapters` component handles both publishing and consuming. Publishing is triggered by the booking lifecycle: after a booking is created or its state changes, the `calendarService_schedulerJobs` component signals `messageBusAdapters` to emit events. Consumption drives availability state updates and appointment coordination. The utility hosts (`continuumCalendarUtility`) also publish booking synchronization events independently of the API request path.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `availabilityEngineEventsBus` | `AvailabilityRecordChanged` | Availability record created or updated | service ID, availability window, change timestamp |
| `availabilityEngineEventsBus` | `ProductAvailabilitySegments` | Product segment created, updated, or removed | product ID, segment data, effective date range |

### AvailabilityRecordChanged Detail

- **Topic**: `availabilityEngineEventsBus`
- **Trigger**: An availability record is created or updated — either via the `/v1/services/{id}/ingest_availability` ingest endpoint or as a side effect of a booking state transition
- **Payload**: Service ID, updated availability window definition, change timestamp
- **Consumers**: Known downstream consumers include other Continuum services that maintain availability caches or drive booking surface rendering
- **Guarantees**: at-least-once (MBus convention)

### ProductAvailabilitySegments Detail

- **Topic**: `availabilityEngineEventsBus`
- **Trigger**: A product availability segment is created, updated, or deleted via `/v1/products/segments` or as part of an availability compilation run
- **Payload**: Product ID, segment definition, effective date range
- **Consumers**: Booking surfaces and inventory services tracking product-level availability windows
- **Guarantees**: at-least-once (MBus convention)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `availabilityEngineEventsBus` | `AvailabilityRecordChanged` | `messageBusAdapters` | Updates internal availability records; may invalidate Redis cache entries |
| `availabilityEngineEventsBus` | `ProductAvailabilitySegments` | `messageBusAdapters` | Reconciles product segment state in PostgreSQL and MySQL availability stores |
| `availabilityEngineEventsBus` | `AppointmentEvents` | `messageBusAdapters` | Updates booking state for appointment-backed bookings; triggers downstream sync if needed |

### AvailabilityRecordChanged (Consumed) Detail

- **Topic**: `availabilityEngineEventsBus`
- **Handler**: `messageBusAdapters` component within `continuumCalendarServiceCalSer`
- **Idempotency**: Expected; duplicate events should result in the same availability state (upsert semantics)
- **Error handling**: MBus retry with eventual dead-letter handling per platform conventions
- **Processing order**: unordered

### ProductAvailabilitySegments (Consumed) Detail

- **Topic**: `availabilityEngineEventsBus`
- **Handler**: `messageBusAdapters` component within `continuumCalendarServiceCalSer`
- **Idempotency**: Expected; segment records are reconciled by product ID and date range
- **Error handling**: MBus retry with eventual dead-letter handling per platform conventions
- **Processing order**: unordered

### AppointmentEvents Detail

- **Topic**: `availabilityEngineEventsBus`
- **Handler**: `messageBusAdapters` component within `continuumCalendarServiceCalSer`
- **Idempotency**: Expected; booking state updates use booking ID as idempotency key
- **Error handling**: MBus retry with eventual dead-letter handling per platform conventions
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found. DLQ configuration is not declared in the federated architecture DSL. Consult MBus platform configuration for DLQ assignments for `availabilityEngineEventsBus` topics.
