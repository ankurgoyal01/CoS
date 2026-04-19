---
service: "travel-search"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

The Getaways Search Service participates in two async messaging systems: it consumes EAN price update messages from an internal **Kafka cluster** and publishes MDS (Merchant Data Service) hotel update events to the internal **Message Bus (MBus)**. It also receives inbound hotel update events from MBus. These async patterns decouple price and inventory data propagation from the synchronous search request path.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| MBus (internal) | `MdsHotelUpdate` | Hotel detail fetch or explicit MDS control API call | hotel ID, updated fields, timestamp |

### MdsHotelUpdate Detail

- **Topic**: MBus (internal message bus — `externalMessageBus_e5f6`)
- **Trigger**: When `hotelDetailsManager` completes a hotel detail merge and determines MDS data has changed, or when the MDS control endpoints (`POST /mds/hotels/{hotelId}/update`, `POST /mds/hotels/bulk-update`) are invoked
- **Payload**: Hotel identifier, updated merchant data fields, event timestamp
- **Consumers**: Downstream MDS consumers within the Continuum platform
- **Guarantees**: at-least-once (JMS / MBus delivery semantics)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Kafka cluster (`externalKafkaCluster_f6a7`) | EAN price update | `travelSearch_kafkaConsumer` | Updates Redis cache and persists price data to MySQL |
| MBus (`externalMessageBus_e5f6`) | Hotel update event | `continuumTravelSearchService` (inbound) | Triggers hotel data refresh within the service |

### EAN Price Update Detail

- **Topic**: Kafka cluster (`externalKafkaCluster_f6a7`) — EAN price update stream
- **Handler**: `travelSearch_kafkaConsumer` (Kafka Streams component) — updates `travelSearch_cacheLayer` with new prices and persists to `travelSearch_persistenceLayer`
- **Idempotency**: Price updates are keyed by hotel and rate plan; re-processing the same message overwrites the existing price record
- **Error handling**: Kafka consumer offset management; failed messages remain in partition for retry up to configured retry limit
- **Processing order**: Ordered per partition (by hotel identifier)

### Hotel Update Event (MBus inbound) Detail

- **Topic**: MBus (`externalMessageBus_e5f6`) — hotel update events
- **Handler**: `continuumTravelSearchService` inbound MBus listener — triggers internal hotel data refresh
- **Idempotency**: Hotel updates are idempotent by hotel ID; repeated events result in the same persisted state
- **Error handling**: JMS re-delivery up to configured retry limit; failed messages routed to dead letter queue
- **Processing order**: unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| MBus DLQ (internal) | MBus hotel update events | Platform-default | > No evidence found of specific alert configuration |

> Kafka DLQ configuration and MBus DLQ names are managed at the platform infrastructure level and are not specified in the service architecture model. Verify with the platform messaging team.
