---
service: "merchant-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The M3 Merchant Service publishes merchant lifecycle events (create and update notifications) to the Voltron message bus (`mbus`) after successful write operations. The service additionally accepts inbound merchant feature and configuration updates via a dedicated mbus topic, enabling asynchronous synchronization from other services. The Voltron `MessageBusNotifier` library handles outbound publishing; the bus integration is feature-flagged by the `mbus.enabled` configuration key.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `merchant_notifier_topic` (configured via `merchant_notifier_topic` config key) | Merchant Create Notification | Successful POST to `/v2.1/merchants` or `/v2.2/merchants/**` | merchant UUID |
| `merchant_notifier_topic` | Merchant Update Notification | Successful PUT to `/v2.1/merchants/{id}` or `/v2.2/merchants/{id}` | merchant UUID |

### Merchant Create Notification Detail

- **Topic**: Value of config key `merchant_notifier_topic`
- **Trigger**: Any successful merchant create operation via the REST API (both standard v2.1 and MMUD v2.2 paths)
- **Payload**: Merchant UUID (`merchantExhibit.getId()`) passed as the identifier in the `MessageBusNotifier.Operation.CREATE` notification
- **Consumers**: Downstream services subscribed to merchant create events (tracked in the central architecture model)
- **Guarantees**: at-most-once — event publishing is best-effort; failures are logged and swallowed to avoid blocking the create response

### Merchant Update Notification Detail

- **Topic**: Value of config key `merchant_notifier_topic`
- **Trigger**: Any successful merchant update operation via the REST API (both standard v2.1 and MMUD v2.2 paths)
- **Payload**: Merchant UUID passed as the identifier in the `MessageBusNotifier.Operation.UPDATE` notification
- **Consumers**: Downstream services subscribed to merchant update events (tracked in the central architecture model)
- **Guarantees**: at-most-once — event publishing is best-effort; failures are logged and swallowed

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.merchantservice_settings` | Merchant Feature or Configuration Sync | Internal mbus listener (Voltron) | Upserts feature flags or configuration values in MySQL |

### Merchant Feature / Configuration Sync Detail

- **Topic**: `jms.topic.merchantservice_settings`
- **Handler**: Voltron mbus consumer receives messages with `type` field of either `feature` or `configuration`, and upserts the named key/value into the merchant's feature or configuration store
- **Payload fields**: `id` (merchant UUID), `type` (`feature` or `configuration`), `name`, `value`, `merchant_id`, `created_at`, `updated_at`
- **Idempotency**: Upsert semantics — re-delivering the same message with the same `name` overwrites the stored value
- **Error handling**: No explicit DLQ documented; failures surfaced through application logs
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase of explicit DLQ configuration.

## Notes

- The `MessageBusNotifier` is started on `@PostConstruct` and stopped on `@PreDestroy` when `mbus.enabled` is `true`.
- The topic name and notification prefix are configured via `merchant_notifier_topic` and `merchant_notifier_prefix` config keys respectively.
- Publishing failures during create/update are caught, logged at ERROR level, and do not fail the HTTP response.
