---
service: "channel-manager-integrator-travelclick"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus, kafka]
---

# Events

## Overview

The service participates in two asynchronous messaging systems. It consumes reservation and cancellation messages delivered by MBus (Groupon's internal message bus), processes them, and publishes response messages back to MBus. In the ARI direction, after processing inbound availability, inventory, and rate push messages from TravelClick via REST, the service publishes those ARI payloads to Kafka for downstream consumers. The shared message schema is defined in the `channel-manager-async-schema` artifact (version 0.0.22).

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| MBus (channel manager response topic) | Channel manager response message | Successful or failed processing of a reservation/cancellation MBus message | Reservation ID, status, TravelClick response |
| Kafka (ARI topic) | ARI notification | Receipt of valid ARI push data via REST endpoints | Hotel code, rate plan code, inventory count, availability restriction, date range |

### Channel Manager Response Message Detail

- **Topic**: MBus channel manager response topic (topic name managed by JTier MessageBus configuration)
- **Trigger**: After the MBus consumer processes a reservation or cancellation and receives a response from TravelClick
- **Payload**: Channel manager response as defined in `channel-manager-async-schema` 0.0.22
- **Consumers**: Channel manager orchestration services (upstream consumers tracked in the central architecture model)
- **Guarantees**: at-least-once (MBus delivery semantics)

### ARI Notification Detail

- **Topic**: Kafka ARI topic (topic name managed by Kafka client configuration)
- **Trigger**: Valid OTA availability, inventory, or rate push received on the REST endpoints (`pushAvailability`, `pushInventory`, `pushRates`)
- **Payload**: OTA XML-derived ARI data including hotel code, date range, rate plan code, inventory count, and restriction status
- **Consumers**: Downstream Getaways services consuming ARI data (tracked in the central architecture model)
- **Guarantees**: at-least-once (Kafka producer semantics with `kafka-clients` 0.10.2.1)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| MBus reservation topic | Reservation message | `cmiTc_mbusConsumer` | Sends OTA reservation XML to TravelClick; persists request/response to MySQL; publishes response to MBus |
| MBus cancellation topic | Cancellation message | `cmiTc_mbusConsumer` | Sends OTA cancellation XML to TravelClick; persists request/response to MySQL; publishes response to MBus |
| MBus DLQ | Failed reservation/cancellation message | `cmiTc_mbusConsumer` | Reprocesses or logs failed messages |

### Reservation Message Detail

- **Topic**: MBus reservation topic (schema from `channel-manager-async-schema`)
- **Handler**: `cmiTc_mbusConsumer` — routes to `cmiTc_travelclickClient` which builds and sends OTA XML
- **Idempotency**: Records are persisted in MySQL; duplicate messages may result in duplicate TravelClick calls (no explicit deduplication layer observed in DSL)
- **Error handling**: DLQ consumption supported; failed messages are written to the dead letter queue for reprocessing
- **Processing order**: unordered (Kafka/MBus partition-level ordering)

### Cancellation Message Detail

- **Topic**: MBus cancellation topic (schema from `channel-manager-async-schema`)
- **Handler**: `cmiTc_mbusConsumer` — routes to `cmiTc_travelclickClient` for OTA cancellation request
- **Idempotency**: Persistence layer records the request/response; no explicit deduplication
- **Error handling**: DLQ-backed retry
- **Processing order**: unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| MBus DLQ (reservation) | MBus reservation topic | Managed by JTier MessageBus configuration | PagerDuty `PEAIXM8`; Splunk alerts |
| MBus DLQ (cancellation) | MBus cancellation topic | Managed by JTier MessageBus configuration | PagerDuty `PEAIXM8`; Splunk alerts |
