---
service: "bookingtool"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [messagebus]
---

# Events

## Overview

The Booking Tool uses the `messagebus` library (v0.3.6) for async event publishing. Events are published to a dedicated JMS topic for booking lifecycle state changes. The service also consumes events via MessageBus for inbound notifications from other Continuum services. This pattern decouples downstream consumers (e.g., notification services, analytics pipelines) from the synchronous reservation flow.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.BookingTool.Services.BookingEngine` | Booking Created | Customer completes a new reservation | booking_id, merchant_id, deal_id, slot_datetime, locale, voucher_code |
| `jms.topic.BookingTool.Services.BookingEngine` | Booking Cancelled | Customer or merchant cancels a reservation | booking_id, merchant_id, cancellation_reason, cancelled_at |
| `jms.topic.BookingTool.Services.BookingEngine` | Booking Rescheduled | Customer reschedules to a new time slot | booking_id, merchant_id, old_slot_datetime, new_slot_datetime |
| `jms.topic.BookingTool.Services.BookingEngine` | Booking CheckedIn | Merchant records customer check-in | booking_id, merchant_id, checked_in_at |

### Booking Created Detail

- **Topic**: `jms.topic.BookingTool.Services.BookingEngine`
- **Trigger**: Customer successfully completes a booking against an available slot
- **Payload**: booking_id, merchant_id, deal_id, slot_datetime, locale, voucher_code, customer_id
- **Consumers**: Rocketman V2 (confirmation email), Appointment Engine, downstream analytics
- **Guarantees**: at-least-once

### Booking Cancelled Detail

- **Topic**: `jms.topic.BookingTool.Services.BookingEngine`
- **Trigger**: Cancellation request is accepted and reservation record is updated to cancelled state
- **Payload**: booking_id, merchant_id, cancellation_reason, cancelled_at, locale
- **Consumers**: Rocketman V2 (cancellation email), Voucher Inventory (voucher reinstatement), downstream analytics
- **Guarantees**: at-least-once

### Booking Rescheduled Detail

- **Topic**: `jms.topic.BookingTool.Services.BookingEngine`
- **Trigger**: Reschedule request is accepted and reservation record is updated with new slot
- **Payload**: booking_id, merchant_id, old_slot_datetime, new_slot_datetime, locale
- **Consumers**: Rocketman V2 (reschedule confirmation email), Appointment Engine
- **Guarantees**: at-least-once

### Booking CheckedIn Detail

- **Topic**: `jms.topic.BookingTool.Services.BookingEngine`
- **Trigger**: Merchant marks a customer as checked in for their appointment
- **Payload**: booking_id, merchant_id, checked_in_at
- **Consumers**: Analytics / reporting pipelines
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| MessageBus inbound | Deal/voucher state changes | `btIntegrationClients` / Domain Services | Updates local deal cache, invalidates availability |

### Inbound MessageBus Events Detail

- **Topic**: MessageBus inbound channel (specific topic names not evidenced in inventory)
- **Handler**: Integration Clients (`btIntegrationClients`) pass events to Domain Services (`btDomainServices`) for processing
- **Idempotency**: No explicit evidence — assumed application-level deduplication
- **Error handling**: No explicit DLQ evidence in inventory
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found of configured dead-letter queues in the service inventory.
