---
service: "message-service"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus, kafka]
---

# Events

## Overview

The CRM Message Service participates in two async messaging systems: **MBus** (Groupon's internal message bus) for publishing campaign metadata to downstream consumers and the EDW analytics pipeline, and **Kafka** for both publishing and consuming `ScheduledAudienceRefreshed` events that drive batch audience assignment processing. The service uses `messagingEventPublishers` to emit events and `messagingKafkaConsumers` to receive them.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| MBus (campaign metadata topic) | `CampaignMetaData` | Campaign state change (create, update, approve) | Campaign ID, metadata fields |
| Kafka (scheduled audience topic) | `ScheduledAudienceRefreshed` | Audience refresh job completion | Audience ID, refresh timestamp |

### CampaignMetaData Detail

- **Topic**: MBus campaign metadata topic
- **Architecture ref**: `messagingEventPublishers` via `messageBus`
- **Trigger**: Campaign creation, update, or approval workflow completes in `messagingCampaignOrchestration`
- **Payload**: Campaign metadata (campaign ID and associated configuration fields)
- **Consumers**: EDW (analytics), and downstream Continuum services subscribed to campaign updates
- **Guarantees**: at-least-once

### ScheduledAudienceRefreshed (Published) Detail

- **Topic**: Kafka scheduled audience topic
- **Architecture ref**: `messagingEventPublishers` via `messageBus`
- **Trigger**: Audience import job completes an audience assignment refresh cycle
- **Payload**: Audience ID, refresh completion timestamp
- **Consumers**: Other services monitoring scheduled audience state; the service itself also consumes this topic
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Kafka (scheduled audience topic) | `ScheduledAudienceRefreshed` | `messagingKafkaConsumers` -> `messagingAudienceImportJobs` | Triggers batch audience export download and assignment rebuild in selected datastore (Bigtable or Cassandra) |

### ScheduledAudienceRefreshed (Consumed) Detail

- **Topic**: Kafka scheduled audience topic
- **Architecture ref**: `messagingKafkaConsumers`
- **Handler**: `messagingKafkaConsumers` delivers the event to `messagingAudienceImportJobs` (Akka actors), which download audience export files from GCP Storage/HDFS, build user-campaign assignments, and write them to the configured datastore
- **Idempotency**: Assignment rebuild is a bulk-replace operation; re-processing the same event overwrites existing assignments with identical data
- **Error handling**: No DLQ configuration is documented in the architecture inventory; Akka actor supervision handles actor-level failures
- **Processing order**: Unordered (each audience ID is processed independently)

## Dead Letter Queues

> No evidence found in the architecture inventory for configured DLQ topics.
