---
service: "travel-inventory"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Getaways Inventory Service participates in Groupon's internal message bus (MBus over JMS/STOMP) both as a publisher and as a consumer. The Message Bus Integration component handles all async messaging. The service publishes reservation and cancel events for downstream processing by the Backpack Reservation Service and other consumers, and consumes order status updates and worker task messages to drive asynchronous workflows.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `reservation.create` | Reservation created | Consumer completes a booking via Shopping API | reservation ID, hotel ID, room type, rate plan, dates, guest info |
| `reservation.cancel` | Reservation cancelled | Consumer or operator cancels a reservation | reservation ID, cancellation reason, timestamp |
| `worker.task.*` | Worker task messages | Background task processing dispatches work items | task ID, task type, payload, status |

### reservation.create Detail

- **Topic**: `reservation.create`
- **Trigger**: A consumer successfully books a Getaways hotel room via the Shopping API reservation endpoint
- **Payload**: Reservation ID, hotel ID, room type ID, rate plan ID, check-in/check-out dates, guest details, pricing breakdown
- **Consumers**: Backpack Reservation Service (`continuumBackpackReservationService`), downstream commerce services
- **Guarantees**: at-least-once

### reservation.cancel Detail

- **Topic**: `reservation.cancel`
- **Trigger**: A reservation is cancelled via the Shopping API cancel endpoint or reverse fulfilment flow
- **Payload**: Reservation ID, cancellation reason, cancellation timestamp, refund eligibility
- **Consumers**: Backpack Reservation Service (`continuumBackpackReservationService`), downstream commerce services
- **Guarantees**: at-least-once

### worker.task.* Detail

- **Topic**: `worker.task.*`
- **Trigger**: Worker Domain dispatches or completes background tasks (e.g., backfill jobs, report generation steps)
- **Payload**: Task ID, task type, execution payload, status
- **Consumers**: Internal -- consumed by the same service's Message Bus Integration for task coordination
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `order.status.*` | Order status updates | Message Bus Integration -> Shopping Domain | Updates reservation state based on order status changes |
| `worker.task.*` | Worker task messages | Message Bus Integration -> Worker Domain | Dispatches and tracks background task execution |

### order.status.* Detail

- **Topic**: `order.status.*`
- **Handler**: Message Bus Integration routes order status events to Shopping Domain Services for reservation state reconciliation
- **Idempotency**: Status updates are expected to be idempotent -- applying the same status transition multiple times results in a no-op if the reservation is already in the target state
- **Error handling**: Failed messages are retried via MBus retry mechanisms; persistent failures are logged via Metrics & Logging
- **Processing order**: unordered

### worker.task.* Detail

- **Topic**: `worker.task.*`
- **Handler**: Message Bus Integration routes task messages to Worker Domain Services for dispatch and execution tracking
- **Idempotency**: Task messages include task IDs; duplicate messages are detected and skipped
- **Error handling**: Failed tasks are logged and may be retried based on task type configuration
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found for explicitly configured dead letter queues in the federated architecture model. Failed messages are expected to be handled by MBus's built-in retry and logging mechanisms. Consult service owner for production DLQ configuration.
