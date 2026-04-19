---
service: "glive-inventory-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

GLive Inventory Service uses the Continuum MessageBus (STOMP/JMS) for asynchronous event publishing and consumption. Both the main service (`continuumGliveInventoryService`) and the worker tier (`continuumGliveInventoryWorkers`) interact with MessageBus. Events cover inventory state changes, GDPR compliance processing, and configuration updates. Topics and queues are configured in the service's `messagebus.yml` configuration file.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Inventory update topic | Inventory Status Update | Product or event inventory changes (create, update, delete) | product_id, event_id, availability, status, timestamp |
| Inventory availability topic | Availability Change | Availability recalculated after reservation or purchase | product_id, event_id, available_quantity, reserved_quantity |
| Reporting topic | Report Generated | Merchant payment report or accounting report completed | report_id, report_type, merchant_id, period |

### Inventory Status Update Detail

- **Topic**: Configured in `messagebus.yml` (inventory update topic)
- **Trigger**: Product or event inventory is created, updated, or deleted via API or background job
- **Payload**: Product ID, event ID, current availability counts, inventory status, timestamp
- **Consumers**: Downstream Continuum services consuming inventory state for deal display and purchase flows
- **Guarantees**: at-least-once

### Availability Change Detail

- **Topic**: Configured in `messagebus.yml` (availability topic)
- **Trigger**: Reservation created, released, or expired; purchase completed; inventory quantities adjusted
- **Payload**: Product ID, event ID, available quantity, reserved quantity, timestamp
- **Consumers**: Groupon Website and other consumer-facing services for real-time availability display
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| GDPR topic | GDPR Data Request | Background job handler | Processes data deletion or export requests for user data within GLive inventory records |
| Configuration topic | Config Update | Configuration handler | Reloads service configuration and feature flags |
| Inventory sync topic | Inventory Sync Request | Background job handler | Triggers re-sync of inventory from third-party providers |

### GDPR Data Request Detail

- **Topic**: Configured in `messagebus.yml` (GDPR topic)
- **Handler**: Background job class that processes GDPR data deletion and export requests, removing or exporting personally identifiable information from inventory, reservation, and reporting records
- **Idempotency**: Yes -- duplicate requests are detected by request ID
- **Error handling**: Failed processing is retried via Resque retry; persistent failures logged and alerted
- **Processing order**: unordered

### Config Update Detail

- **Topic**: Configured in `messagebus.yml` (configuration topic)
- **Handler**: In-process handler that reloads configuration values and feature flags from the message payload
- **Idempotency**: Yes -- configuration state is overwritten idempotently
- **Error handling**: Configuration reload failures are logged; service continues with previous configuration
- **Processing order**: unordered (latest value wins)

## Dead Letter Queues

Dead letter queue handling is managed at the MessageBus infrastructure level. Failed messages that exceed retry limits are routed to the platform DLQ for the respective topic.

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| Platform DLQ | All subscribed topics | Per MessageBus platform policy | Monitored via Sonoma metrics and Elastic APM |

> MessageBus configuration details including topic names, queue names, and subscription settings are defined in the service's `messagebus.yml` configuration file. Refer to that file for exact topic/queue identifiers.
