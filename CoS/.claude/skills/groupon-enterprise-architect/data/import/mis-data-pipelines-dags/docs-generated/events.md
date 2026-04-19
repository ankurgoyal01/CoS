---
service: "mis-data-pipelines-dags"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["kafka"]
---

# Events

## Overview

`mis-data-pipelines-dags` participates in async messaging exclusively as a consumer. The Janus Spark Streaming job, submitted by the `mds-janus` DAG, consumes deal ID events from a Kafka (MSK) tier-2 topic. The service does not publish its own Kafka events — it reads from the message bus and writes results into Redis queues and Hive tables as side effects. The Airflow DAG orchestrator connects Kafka consumption to GCP Dataproc cluster lifecycle management.

## Published Events

> No evidence found in codebase. This service does not publish async events to any message bus.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Janus tier-2 Kafka topic (MSK) | Deal ID streaming event | `mds-janus` Spark Streaming job (`com.groupon.mds.jobs.MDSJanusStreamingApplication`) | Adds deal IDs to Redis queue for batch worker processing |

### Janus Tier-2 Kafka Stream Detail

- **Topic**: Janus tier-2 Kafka topic (MSK, consumer group `mds_janus_msk_prod_3`)
- **Handler**: `com.groupon.mds.jobs.MDSJanusStreamingApplication` (Spark Streaming, submitted via `mds-janus` DAG on Dataproc cluster `dataproc-ephemeral-cluster-mds-janus`)
- **Idempotency**: Backpressure-controlled via Spark Streaming backpressure (`spark.streaming.backpressure.enabled=true`, initial rate 30, max rate per partition 1000, min rate 100)
- **Error handling**: Spark executor restarts via YARN; cluster has idle TTL of 3600 seconds before auto-deletion
- **Processing order**: Unordered (Kafka partitioned stream, batch interval 5 seconds, shuffle partitions 240)
- **Spark config**: 27 executor instances, 5 cores each, 2g driver and executor memory, KryoSerializer not used (default Java serializer)

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration identified.
