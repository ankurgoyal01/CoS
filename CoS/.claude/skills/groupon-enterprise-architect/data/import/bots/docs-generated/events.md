---
service: "bots"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

BOTS uses Groupon's internal Message Bus (`messageBus`) for asynchronous event processing. The `continuumBotsWorker` both publishes booking lifecycle events and consumes deal and GDPR events. The `botsWorkerMbusConsumersComponent` handles all inbound message routing; outbound events are published by `botsWorkerJobServicesComponent` following job execution.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `booking.events.created` | booking-created | New booking successfully persisted | booking ID, merchant ID, service ID, consumer ID, scheduled time |
| `booking.events.confirmed` | booking-confirmed | Booking acknowledgment completed | booking ID, merchant ID, confirmation reference |
| `booking.events.rescheduled` | booking-rescheduled | Booking rescheduled to new time slot | booking ID, merchant ID, old scheduled time, new scheduled time |
| `booking.events.canceled` | booking-canceled | Booking canceled by merchant or system | booking ID, merchant ID, cancellation reason |
| `booking.events.checked-in` | booking-checked-in | Customer checked in against a booking | booking ID, merchant ID, checkin timestamp |

### booking-created Detail

- **Topic**: `booking.events.created`
- **Trigger**: A new booking is created via `POST /merchants/{id}/bookings` and persisted successfully to `continuumBotsMysql`
- **Payload**: booking ID, merchant ID, service ID, consumer ID, scheduled time, campaign reference
- **Consumers**: Downstream Continuum services tracking booking state (not enumerated in this inventory)
- **Guarantees**: at-least-once

### booking-confirmed Detail

- **Topic**: `booking.events.confirmed`
- **Trigger**: A merchant acknowledges a booking via `PUT /merchants/{id}/bookings/{bookingId}/acknowledge`
- **Payload**: booking ID, merchant ID, confirmation reference
- **Consumers**: Notification and reporting consumers (not enumerated in this inventory)
- **Guarantees**: at-least-once

### booking-rescheduled Detail

- **Topic**: `booking.events.rescheduled`
- **Trigger**: A booking is rescheduled via `PUT /merchants/{id}/bookings/{bookingId}/reschedule`
- **Payload**: booking ID, merchant ID, old scheduled time, new scheduled time
- **Consumers**: Downstream services tracking booking state changes
- **Guarantees**: at-least-once

### booking-canceled Detail

- **Topic**: `booking.events.canceled`
- **Trigger**: A booking is canceled via `PUT /merchants/{id}/bookings/{bookingId}/cancel`
- **Payload**: booking ID, merchant ID, cancellation reason
- **Consumers**: Notification and reporting consumers
- **Guarantees**: at-least-once

### booking-checked-in Detail

- **Topic**: `booking.events.checked-in`
- **Trigger**: A customer is checked in via `PUT /merchants/{id}/bookings/{bookingId}/checkin`
- **Payload**: booking ID, merchant ID, checkin timestamp
- **Consumers**: Voucher redemption and reporting consumers
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `deal.onboarding` | deal-onboarding | `botsWorkerMbusConsumersComponent` | Initializes merchant booking configuration (campaigns, services, availability) |
| `deal.offboarding` | deal-offboarding | `botsWorkerMbusConsumersComponent` | Deactivates or removes merchant booking configuration for the deal |
| `gdpr.erasure` | gdpr-erasure | `botsWorkerMbusConsumersComponent` | Erases personal data from booking records in `continuumBotsMysql` |

### deal-onboarding Detail

- **Topic**: `deal.onboarding`
- **Handler**: `botsWorkerMbusConsumersComponent` routes to `botsWorkerJobServicesComponent` which initializes merchant booking setup
- **Idempotency**: Idempotency expected — re-processing the same onboarding event should not duplicate merchant configuration
- **Error handling**: Retry via Message Bus retry infrastructure; failed messages may go to a dead-letter queue
- **Processing order**: unordered

### deal-offboarding Detail

- **Topic**: `deal.offboarding`
- **Handler**: `botsWorkerMbusConsumersComponent` routes to `botsWorkerJobServicesComponent` which deactivates merchant booking state
- **Idempotency**: Idempotency expected — deactivation of already-inactive configuration is a no-op
- **Error handling**: Retry via Message Bus retry infrastructure
- **Processing order**: unordered

### gdpr-erasure Detail

- **Topic**: `gdpr.erasure`
- **Handler**: `botsWorkerMbusConsumersComponent` routes to `botsWorkerJobServicesComponent` which deletes or anonymizes personal data in `continuumBotsMysql`
- **Idempotency**: Must be idempotent — re-processing an erasure request on already-erased data must not error
- **Error handling**: Retry with dead-letter routing; erasure failures are escalated
- **Processing order**: unordered

## Dead Letter Queues

> Dead-letter queue names and retention policies are managed by the Message Bus infrastructure configuration and are not explicitly defined in this repository inventory. Contact the BOTS team for operational DLQ details.
