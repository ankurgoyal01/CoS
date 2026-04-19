---
service: "janus-user-activity-store"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["gcs-parquet"]
---

# Events

## Overview

Janus User Activity Store does not publish or consume Kafka, Pub/Sub, or message-bus events directly. Its event input is the Janus canonical event stream materialized as hourly Parquet files on Google Cloud Storage by an upstream Janus pipeline. The service reads these files in batch once per hour and writes results to Bigtable. There are no async event subscriptions or publications.

## Published Events

> Not applicable. This service does not publish events to any message broker or queue. Write results go directly to Google Cloud Bigtable.

## Consumed Events

The service does not subscribe to a message broker. Instead it reads materialized Janus canonical events from GCS Parquet partitions.

| Source | Format | Partition Pattern | Handler | Side Effects |
|--------|--------|-------------------|---------|-------------|
| GCS Janus canonical bucket | Parquet (Snappy) | `ds={date}/hour={hour}` | `UserActivityEngine.process()` reads via Spark `spark.read.parquet()` | Filtered and translated records written to Bigtable |

### Janus Canonical Event Detail

- **Source path**: `gs://grpn-dnd-prod-pipelines-yati-canonicals/kafka/region=na/source=janus-all/ds={date}/hour={hour}/` (production)
- **Handler**: `UserActivityEngine.process()` — reads parquet into a Spark DataFrame, parses the `value` column as a JSON `Map[String, String]`, and iterates partitions
- **Idempotency**: The Spark job processes a fixed hourly partition; re-running for the same partition overwrites Bigtable rows with the same row key (`consumerId`)
- **Error handling**: Exceptions at the partition level are caught and logged; the Dataproc Spark job fails and surfaces to Airflow for alerting
- **Processing order**: unordered (Spark partition parallelism)

### Supported User Activity Event Types

The following event names from the Janus canonical stream are recognized as user activity events:

| Event Name | Column Family | Captured Attributes |
|------------|--------------|---------------------|
| `emailOpenHeader` | core (`a`) | `emailSendId`, `emailSubject` |
| `emailSend` | core (`a`) | `emailSendId`, `emailSubject` |
| `pushNotification` | core (`a`) | `marketingText` |
| `locationTracking` | core (`a`) | `clientPlatform`, `latitude`, `longitude` |
| `dealView` | core (`a`) | `dealPermalink` |
| `genericPageView` | core (`a`) | `pageViewType`, `fullUrl` |
| `search` | core (`a`) | `searchString` |
| `dealPurchase` | extended (`extended`) | `dealPermalink` |

All event types also capture the required base attributes: `consumerId`, `platform`, `eventTime`, `event`, `country`.

## Dead Letter Queues

> Not applicable. This service does not use message brokers or queues. Failed Spark partitions result in job failure surfaced through Airflow DAG alerts.
