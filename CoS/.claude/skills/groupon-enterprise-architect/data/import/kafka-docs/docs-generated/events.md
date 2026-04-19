---
service: "kafka-docs"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

Kafka is itself the messaging system documented in this repo. The `kafka-docs` documentation site does not publish or consume any Kafka events on its own — it is a static documentation pipeline. The documented Kafka platform, however, is the central event-streaming backbone for Groupon, supporting thousands of topics across on-prem and cloud clusters. This file describes the key topics and patterns documented in the `kafka-docs` knowledge base.

## Published Events (Kafka Platform — Active Audit Topics)

The `kafka-active-audit` daemon produces fabricated health-check messages to special audit topics on each cluster. These are the only topics directly owned by the kafka-docs/Data Systems service.

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Configurable per audit daemon instance | `active-audit-heartbeat` | Periodic (continuous daemon) | UUID, timestamp |

### active-audit-heartbeat Detail

- **Topic**: One configurable audit topic per kafka-active-audit instance; spread across all brokers in the target cluster
- **Trigger**: Periodic emission by the `kafka-active-audit` daemon running on `kafka-active-audit{1-2}.snc1`, `kafka-active-audit{1-2}.sac1`, `kafka-active-audit{1-4}.dub1`
- **Payload**: UUID + timestamp per message
- **Consumers**: Same `kafka-active-audit` daemon instance (self-consuming for round-trip latency measurement)
- **Guarantees**: at-least-once; duplicates and missing messages are both monitored as exceptions

## Consumed Events (Kafka Platform — Active Audit Topics)

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Configurable audit topic | `active-audit-heartbeat` | kafka-active-audit daemon consumer | Measures round-trip latency; fires PagerDuty alert if messages missing or duplicated |

### active-audit-heartbeat Consumption Detail

- **Topic**: Same topic the daemon produces to (self-contained loop)
- **Handler**: `kafka-active-audit` daemon at `https://github.groupondev.com/data/kafka-active-audit`
- **Idempotency**: Not applicable — duplicates are detected as anomalies and alert
- **Error handling**: Missing or late messages trigger alerts on the PagerDuty service `P4VBAQS`
- **Processing order**: ordered per partition

## Kafka Topic Conventions (for client service teams)

The following topic-level conventions are documented for teams using Kafka:

- **Auto-topic creation**: Disabled on production and aggregate clusters; enabled on non-production local clusters and gensandbox MSK.
- **Default retention**: 96 hours (4 days) on production clusters.
- **Default offset retention**: 1 day; consumer groups stopped for more than 1 day will have Kafka-stored offsets removed.
- **Default partition count**: 25 on production clusters.
- **Replication factor**: 3 (all messages stored on leader broker plus 2 replicas).
- **Message size limit**: `message.max.bytes` = 10,000,000 bytes (10 MB) on brokers; consumers must configure `fetch.message.max.bytes` = 10,000,000 for old 0.8-protocol consumers.

## Mirrored Topics (Hydra Aggregate Clusters)

MirrorMaker replicates topics from SNC1 Local and SAC1 Local to SNC1 Aggregate and SAC1 Aggregate clusters. Known high-volume mirrored topic example:

| Topic | Description |
|-------|-------------|
| `janus-all` | Janus canonical event stream; mirrored to aggregate clusters; historically exhibits mirror lag of 1 hour+ during peak traffic (Black Friday, Cyber Monday) |
| `tracky_json_nginx` | Raw tracking events; planned split between SNC1 and SAC1 colos |
| `mobile_tracking` | Mobile tracking events; planned split between SNC1 and SAC1 colos |

## Dead Letter Queues

> No evidence found in codebase. Kafka at Groupon does not use a dedicated DLQ pattern; consumer groups that fall behind or encounter errors are monitored via `kafka_consumer_offset_topic_[topic]_consumerid_[id]_partition_[n]_lag` Wavefront metrics.
