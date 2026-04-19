---
service: "appointment_engine"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The appointment engine participates in Groupon's Message Bus (JMS topic-based pub/sub) as both a publisher and consumer. It publishes appointment lifecycle events to notify downstream services (e.g., notification systems, merchant tools) and consumes events from the Availability Engine, Orders Service, Voucher Inventory Service, and GDPR pipeline. Background event processing is handled by the `continuumAppointmentEngineUtility` Resque worker.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.BookingEngine.AppointmentEngine.Events` | Appointment lifecycle event | Any appointment state transition (create, confirm, decline, reschedule, attend, miss, cancel) | appointment ID, reservation ID, state, deal ID, consumer ID, merchant ID, scheduled time |

### Appointment Lifecycle Event Detail

- **Topic**: `jms.topic.BookingEngine.AppointmentEngine.Events`
- **Trigger**: Any state transition on an appointment record: creation, confirmation, decline, reschedule, attend, miss, cancellation
- **Payload**: appointment ID, reservation ID, new state, deal ID, consumer ID, merchant ID, scheduled appointment time, voucher ID
- **Consumers**: Online Booking Notifications service (triggers consumer/merchant notifications); > additional consumers tracked in central architecture model
- **Guarantees**: at-least-once (JMS topic delivery)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `BookingEngine.AvailabilityEngine.Events` | Availability slot event | Availability event processor | Updates reservation/appointment availability state; triggers slot coordination |
| `Orders.VisInventoryUnits.StatusChanged` | Order inventory unit status change | Order status change processor | Updates appointment state based on voucher/order fulfillment status |
| `InventoryUnits.Updated.Vis` | Inventory unit updated | Inventory update processor | Syncs appointment state with voucher inventory changes |
| `gdpr.account.v1.erased` | GDPR account erasure | GDPR erasure job (Resque) | Deletes or anonymizes personal data for the erased consumer account |

### BookingEngine.AvailabilityEngine.Events Detail

- **Topic**: `BookingEngine.AvailabilityEngine.Events`
- **Handler**: Availability event processor — updates appointment/reservation records to reflect availability changes; coordinates with Availability Engine on slot state
- **Idempotency**: > No evidence found in codebase.
- **Error handling**: > No evidence found in codebase. Likely Resque retry with backoff.
- **Processing order**: unordered

### Orders.VisInventoryUnits.StatusChanged Detail

- **Topic**: `Orders.VisInventoryUnits.StatusChanged`
- **Handler**: Order status change processor — transitions appointment state (e.g., marks appointment as cancellable if order is refunded)
- **Idempotency**: > No evidence found in codebase.
- **Error handling**: > No evidence found in codebase. Likely Resque retry with backoff.
- **Processing order**: unordered

### InventoryUnits.Updated.Vis Detail

- **Topic**: `InventoryUnits.Updated.Vis`
- **Handler**: Inventory update processor — syncs appointment state with changes to the underlying voucher/inventory unit
- **Idempotency**: > No evidence found in codebase.
- **Error handling**: > No evidence found in codebase.
- **Processing order**: unordered

### gdpr.account.v1.erased Detail

- **Topic**: `gdpr.account.v1.erased`
- **Handler**: GDPR erasure Resque job — identifies all appointment and reservation records belonging to the erased consumer account and deletes or anonymizes personal data fields
- **Idempotency**: Designed to be safe to re-run (delete/anonymize is idempotent)
- **Error handling**: Resque retry; failed erasures must be re-processed to meet GDPR obligations
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase for explicit DLQ configuration. Resque provides retry mechanisms; failed jobs remain in the failed queue for inspection.
