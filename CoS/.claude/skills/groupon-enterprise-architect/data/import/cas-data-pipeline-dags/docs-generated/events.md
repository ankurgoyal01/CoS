---
service: "cas-data-pipeline-dags"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["kafka"]
---

# Events

## Overview

`cas-data-pipeline-dags` interacts with Kafka exclusively as a **consumer** via the Janus-YATI DAG. The Janus-YATI Spark Structured Streaming job subscribes to the `arbitration_log` Kafka topic, reads arbitration log messages, and writes them to GCS in Muncher format. All other pipelines in this service are batch-oriented and do not publish or consume events via a message bus.

## Published Events

> No evidence found in codebase. This service does not publish any events to a message bus.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `arbitration_log` | Arbitration log record (loggernaut-json / Muncher) | `cas_janus_yati_job` Spark Structured Streaming job | Writes records to GCS path `gs://grpn-dnd-stable-analytics-grp-push-platform/user/janus-yati` |

### `arbitration_log` Kafka Topic Detail

- **Topic**: `arbitration_log`
- **Bootstrap servers**: `kafka-grpn-consumer.grpn-dse-stable.us-west-2.aws.groupondev.com:9094`
- **Consumer group**: `cas_stable_arbitration_log_2`
- **Message format**: `loggernaut-json` / `outputFormat=muncher`
- **Handler**: `com.groupon.janus.yati.job.file.KafkaToFileJobMain` — Spark Structured Streaming micro-batch job submitted to Dataproc via the `arbitration_janus_yati` DAG
- **Output path**: `gs://grpn-dnd-stable-analytics-grp-push-platform/user/janus-yati`
- **Checkpoint location**: `gs://grpn-dnd-stable-analytics-grp-push-platform/mezzanine_checkpoint/region=na/source=arbitration_log`
- **Batch interval**: 60,000 ms (60 seconds)
- **Max offsets per trigger**: 1,000,000
- **SSL**: TLS keystore (`cas-keystore.jks`) loaded via Dataproc cluster secret init action
- **Idempotency**: Checkpoint-based — Spark Structured Streaming checkpointing ensures exactly-once semantics for GCS output
- **Processing order**: Unordered within micro-batch window

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration is present.
