---
service: "janus-muncher"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [gcs-file-based]
---

# Events

## Overview

Janus Muncher does not publish or consume events via a message broker such as Kafka or Pub/Sub directly. Its event-stream integration is file-based: upstream Janus Yati writes canonical Parquet files to GCS paths structured as `kafka/region=na/source=janus-all/ds=$dates/hour=$hours/*`, and Janus Muncher reads from these paths as its primary input. The "topic" field in configuration (`topic = "janus-all"`) identifies the logical source, but no live Kafka consumer or producer exists in this service. Output is also written to GCS, not published to a message bus.

## Published Events

> No evidence found in codebase.

This service does not publish to any message broker topic or queue. Outputs are written as Parquet files to GCS destination paths. Downstream consumers poll these GCS paths directly or query via Hive.

## Consumed Events

> No evidence found in codebase.

This service does not subscribe to any message broker topic or queue. Input is read from pre-written GCS Parquet files, not from a live message stream.

## File-Based Data Input (Logical Event Source)

Although not a message broker subscription, the following GCS paths serve as the functional equivalent of consumed topics:

| Logical Topic | GCS Path Template | Format | Handler |
|---------------|------------------|--------|---------|
| `janus-all` (non-SOX) | `gs://grpn-dnd-prod-pipelines-yati-canonicals/kafka/region=na/source=janus-all/ds=$dates/hour=$hours/*` | Parquet | `JanusAllParquetReader` / `JanusAllJsonReader` |
| `janus-all` (SOX) | `gs://grpn-dnd-prod-etl-grp-gdoop-sox-db/kafka/region={na,intl}/source={janus-cloud-all-sox,janus-cloud-all-sox_snc1,janus-all-sox_snc1}/ds=$dates/hour=$hours/*` | Parquet | `JanusAllParquetReader` |

## Dead Letter Queues

> No evidence found in codebase.

No DLQ mechanism is used. Failed Spark job instances are retried via the Airflow backfill DAG. Corrupt record checks are configurable via `corruptRecordCheck` in the conf file and emit metrics when enabled; they do not route records to a DLQ.
