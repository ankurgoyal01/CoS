---
service: "getaways-partner-integrator"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

Getaways Partner Integrator participates in two async messaging systems: Kafka and Groupon MBus (JMS). It consumes partner inbound messages from Kafka topics and bidirectionally interacts with MBus — consuming `InventoryWorkerMessage` events and publishing outbound `InventoryWorkerMessage` events to trigger downstream inventory processing.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `grouponMessageBus_7a2d` (MBus) | `InventoryWorkerMessage` | Mapping or ARI processing completion triggers outbound inventory worker task | Inventory identifiers, operation type, partner mapping references |

### InventoryWorkerMessage (Published) Detail

- **Topic**: Groupon MBus (`grouponMessageBus_7a2d`)
- **Trigger**: Completion of an ARI update or mapping workflow that requires downstream inventory processing
- **Payload**: `InventoryWorkerMessage` — contains inventory identifiers and the operation type to be executed by downstream workers
- **Consumers**: Getaways Inventory Service workers (downstream consumers of MBus InventoryWorkerMessage)
- **Guarantees**: at-least-once (JMS/MBus delivery semantics via `jtier-messagebus-client`)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Kafka partner inbound topic (`grouponKafkaCluster_2c7f`) | Partner inbound message | `getawaysPartnerIntegrator_kafkaConsumer` → `getawaysPartnerIntegrator_mappingService` | Triggers mapping validation and ARI processing; may write to MySQL |
| `grouponMessageBus_7a2d` (MBus) | `InventoryWorkerMessage` | `mbusWorker` → `getawaysPartnerIntegrator_mappingService` | Triggers inventory mapping workflow; reads/writes MySQL; may produce outbound MBus message |

### Kafka Partner Inbound Message Detail

- **Topic**: Partner inbound Kafka topic on `grouponKafkaCluster_2c7f`
- **Handler**: `getawaysPartnerIntegrator_kafkaConsumer` receives the message and delegates to `getawaysPartnerIntegrator_mappingService` for processing
- **Idempotency**: No evidence of explicit idempotency guards; delivery semantics are at-least-once (Kafka 0.10.2.1 consumer)
- **Error handling**: No dead-letter queue configuration found in inventory; error handling to be confirmed with service owner
- **Processing order**: Unordered (standard Kafka partition-level ordering)

### InventoryWorkerMessage (Consumed) Detail

- **Topic**: Groupon MBus (`grouponMessageBus_7a2d`)
- **Handler**: `mbusWorker` receives the message and delegates to `getawaysPartnerIntegrator_mappingService`
- **Idempotency**: No evidence found of explicit idempotency controls
- **Error handling**: JMS redelivery and retry governed by MBus broker configuration; no service-level DLQ evidence found
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found of DLQ configuration for either the Kafka or MBus consumers. Contact the Travel team for operational DLQ policies.
