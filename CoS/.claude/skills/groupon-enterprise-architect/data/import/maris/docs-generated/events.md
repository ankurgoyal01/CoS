---
service: "maris"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

MARIS uses the Groupon MBus (JMS-based message bus) for all asynchronous messaging. It publishes inventory unit update events and GDPR completion events, and consumes order status change events and GDPR erasure request events. The `jtier-messagebus-client` library handles connection management and topic/queue interactions.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `InventoryUnits.Updated.Mrgetaways` | Inventory unit update | Unit status transition or state change | Unit ID, status, updated fields |
| `UpdatedSnapshot` | Snapshot update | Unit or reservation data snapshot published | Snapshot data, entity reference |
| `gdpr.erased.complete` | GDPR erasure completion | GDPR erasure workflow completes for a subject | Subject identifier, erasure confirmation |

### InventoryUnits.Updated.Mrgetaways Detail

- **Topic**: `InventoryUnits.Updated.Mrgetaways`
- **Trigger**: An inventory unit undergoes a status transition or data update (e.g., reservation confirmed, unit redeemed, unit cancelled)
- **Payload**: Unit ID, new status, timestamp of change, relevant unit fields
- **Consumers**: Travel Search Service, Deal Catalog Service, and other downstream Getaways consumers tracking unit state
- **Guarantees**: at-least-once

### UpdatedSnapshot Detail

- **Topic**: `UpdatedSnapshot`
- **Trigger**: A full snapshot of unit or reservation state is published, typically after a significant lifecycle event
- **Payload**: Full snapshot of the entity state at time of publication
- **Consumers**: Downstream analytics or search index consumers
- **Guarantees**: at-least-once

### gdpr.erased.complete Detail

- **Topic**: `gdpr.erased.complete`
- **Trigger**: GDPR data erasure processing completes for a given data subject
- **Payload**: Subject identifier, confirmation of erasure
- **Consumers**: Groupon GDPR orchestration service tracking erasure completion
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `Orders.StatusChanged` | Order status change | `marisEventHandlers` — Order Status Consumer | Triggers payment capture, reversal, or cancellation workflows; updates unit and reservation state in `marisMySql` |
| `gdpr.erased` | GDPR erasure request | `marisEventHandlers` — GDPR Erasure Consumer | Erases personally identifiable data for the specified subject from `marisMySql`; publishes `gdpr.erased.complete` |

### Orders.StatusChanged Detail

- **Topic**: `Orders.StatusChanged`
- **Handler**: Message bus consumer within the `marisEventHandlers` component; dispatches to core orchestration services for business logic
- **Idempotency**: Order status transitions are driven by unique order/unit identifiers; duplicate events for the same transition are expected to be handled safely
- **Error handling**: JTier message bus client retry semantics apply; persistent failures may result in dead-letter handling per MBus platform policy
- **Processing order**: Unordered (events are processed as received; idempotent state machine in the persistence layer guards consistency)

### gdpr.erased Detail

- **Topic**: `gdpr.erased`
- **Handler**: GDPR erasure consumer within `marisEventHandlers`; erases PII fields from reservation and unit records in `marisMySql`
- **Idempotency**: Erasure is applied by subject identifier; re-processing an already-erased subject is safe
- **Error handling**: MBus platform retry policy applies; failures are escalated for manual review given compliance obligations
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found for explicitly configured DLQ names in the architecture model. DLQ handling follows the MBus platform default policy managed by the Continuum Platform team.
