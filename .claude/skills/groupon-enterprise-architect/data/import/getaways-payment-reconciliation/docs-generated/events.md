---
service: "getaways-payment-reconciliation"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Getaways Payment Reconciliation consumes one asynchronous event stream: inventory-units-updated messages from the internal MBus (JMS). This is the mechanism by which the service learns about new or updated Getaways reservations that must be matched against EAN invoices. The service does not publish any async events; all outbound communication is via synchronous HTTP or SMTP.

## Published Events

> No evidence found in codebase of any events published by this service.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `messageBusInventoryUnitsUpdatedTopic` | Inventory Units Updated | Message Bus Consumer → Message Bus Processor | Fetches unit details from Maris; persists reservation record to MySQL |

### Inventory Units Updated Detail

- **Topic**: `messageBusInventoryUnitsUpdatedTopic` (MBus JMS topic; stub ID `messageBusInventoryUnitsUpdatedTopic_unk_4c1d` in architecture model)
- **Handler**: `getawaysPaymentReconciliation_messageBusConsumer` delivers message to `messageBusProcessor`, which calls `marisClient` for unit details and writes to `jdbiDaos`
- **Idempotency**: No explicit idempotency mechanism documented in codebase
- **Error handling**: No evidence found of dead-letter queue or explicit retry configuration in repository
- **Processing order**: Unordered (JMS topic)

## Dead Letter Queues

> No evidence found in codebase of dead-letter queue configuration for the MBus consumer.
