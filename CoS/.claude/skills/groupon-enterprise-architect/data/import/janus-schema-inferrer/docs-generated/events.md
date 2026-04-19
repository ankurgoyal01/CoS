---
service: "janus-schema-inferrer"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

Janus Schema Inferrer is a pure consumer of both Kafka and MBus message streams. It does not publish events to either bus. Instead, it samples messages from configured topics, processes the extracted payloads, and persists results synchronously to the Janus Metadata REST API. All async interaction is inbound only.

## Published Events

> No evidence found in codebase. This service does not publish any events to Kafka or MBus.

## Consumed Events

### Kafka Topics (Production — us-central1)

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `msys_remotebounce` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `global_subscription_service` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `tracky` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `tracky_json_nginx` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `push_service` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `mobile_tracking` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `mobile_notifications` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `mobile_proximity_locations` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `grout_access` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `rocketman_send` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `msys_inbandbounce` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `msys_listunsub` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `msys_delivery` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `msys_fbl` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |
| `cdp_ingress` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |

> Source: `src/main/resources/config/cloud/kafka/production-us-central1.yml`

### Kafka Topics (Production — eu-west-1)

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `cdp_ingress` | raw stream messages | `KafkaStreamConsumer` + `KafkaEventExtractor` | Schema inferred and persisted to Janus |

> Source: `src/main/resources/config/cloud/kafka/production-eu-west-1.yml`

### MBus Topics (Production — us-central1, selected)

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.consumer.v3.consumers` | consumer updates | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.clo.claims` | CLO claim events | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.dynamic_pricing.program_price_events` | pricing events | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.dealCatalog.deals.v1.dealSnapshot` | deal snapshots | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.Orders.OrderSnapshots` | order snapshots | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.Orders.OrderProcessingActivities` | order processing | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.users.account.v1.created` | account creation | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.users.account.v1.deactivated` | account deactivation | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.users.account.v2.registered` | account registration | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.coupon.redemption` | coupon redemption | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.ShoppingCartUpdate` | cart update events | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.gdpr.account.v1.erased` | GDPR erasure | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.identity_service.identity.v1.event` | identity events | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.epods.booking.events` | booking events | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |
| `jms.topic.partnerservice.onboarding.events` | partner onboarding | `MBusConsumer` + `MBusEventExtractor` | Schema inferred and persisted to Janus |

> This is a representative selection. The full production MBus topic list (50+ topics) is defined in `src/main/resources/config/cloud/mbus/production-us-central1.yml`.

### Consumed Events Detail

- **Handler**: `streamIngestion` component draws a sample batch (Kafka: `sampleSize=250` messages; MBus: `consumerSampleSize=250` messages) from each configured topic within the `consumerTimeoutMs` window, then passes sampled bytes to `eventExtraction`
- **Idempotency**: Each hourly run is independent; schemas are merged/unioned with in-memory state for the duration of a single run. There is no cross-run deduplication — Janus Metadata service handles idempotent persistence
- **Error handling**: Malformed JSON messages are skipped with a logged warning (`UnsupportedOperationException` in `SchemaProcessor`). Kafka parse errors from `LoggernautParser` are caught and logged. Individual topic failures do not abort the full run
- **Processing order**: Unordered — Kafka topics are processed in `parallelStream()`; Spark inference runs in parallel per topic

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration is present. Malformed messages are skipped (logged and discarded).
