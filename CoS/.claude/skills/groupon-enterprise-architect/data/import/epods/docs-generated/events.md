---
service: "epods"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

EPODS participates in asynchronous messaging via the Groupon internal message bus (`messageBus`) using JMS/STOMP protocol through `jtier-messagebus-client`. It publishes three event types — `AvailabilityUpdate`, `VoucherRedemption`, and `BookingStatusChange` — and consumes two handler event types — `AvailabilityMessageHandler` and `VoucherMessageHandler`. This async layer decouples EPODS from downstream consumers for availability sync and voucher lifecycle processing.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `messageBus` | `AvailabilityUpdate` | Availability data received from partner system (poll or webhook) | dealId, partnerSlots, effectiveDateTime, partnerId |
| `messageBus` | `VoucherRedemption` | Partner system confirms a voucher has been redeemed | voucherId, bookingId, redemptionTime, partnerId |
| `messageBus` | `BookingStatusChange` | Booking status changes at the partner system (confirm, cancel, modify) | bookingId, previousStatus, newStatus, partnerId, changedAt |

### AvailabilityUpdate Detail

- **Topic**: `messageBus`
- **Trigger**: Availability sync job completes a partner poll, or an inbound partner webhook delivers an availability change notification
- **Payload**: dealId, partnerSlots (list of available time slots), effectiveDateTime, partnerId
- **Consumers**: Calendar Service (`continuumCalendarService`), Ingestion Service (`continuumIngestionService`)
- **Guarantees**: at-least-once

### VoucherRedemption Detail

- **Topic**: `messageBus`
- **Trigger**: Partner system confirms successful voucher redemption during a booking or check-in flow
- **Payload**: voucherId, bookingId, redemptionTime, partnerId
- **Consumers**: Orders Service (`continuumOrdersService`), CFS (`continuumCfsService`)
- **Guarantees**: at-least-once

### BookingStatusChange Detail

- **Topic**: `messageBus`
- **Trigger**: Partner system notifies EPODS of a booking status transition (confirmed, cancelled, modified) via webhook or sync
- **Payload**: bookingId, previousStatus, newStatus, partnerId, changedAt
- **Consumers**: Orders Service (`continuumOrdersService`), Booking Tool (`bookingToolService`)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `messageBus` | `AvailabilityMessageHandler` | Internal availability message handler | Updates availability cache in `continuumEpodsRedis`; may trigger re-sync to partner |
| `messageBus` | `VoucherMessageHandler` | Internal voucher message handler | Updates booking/voucher state in `continuumEpodsPostgres`; may call partner API to confirm redemption |

### AvailabilityMessageHandler Detail

- **Topic**: `messageBus`
- **Handler**: Receives availability change events from upstream Groupon systems and reconciles partner-side availability data
- **Idempotency**: Processed using booking/slot identifiers stored in `continuumEpodsPostgres` to prevent duplicate updates
- **Error handling**: Retry via `jtier-messagebus-client` retry policy; dead-letter on repeated failure
- **Processing order**: unordered

### VoucherMessageHandler Detail

- **Topic**: `messageBus`
- **Handler**: Receives voucher lifecycle events and coordinates partner-side redemption or cancellation actions
- **Idempotency**: Voucher ID used as idempotency key; duplicate events result in no-op if state already updated
- **Error handling**: Retry via `jtier-messagebus-client`; failed messages dead-lettered for investigation
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found of explicitly named DLQ topics in the architecture model. Dead-letter behavior is managed by `jtier-messagebus-client` configuration. Refer to the service repository and JTier message bus configuration for DLQ names and retention policies.
