---
service: "user-behavior-collector"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka, hdfs]
---

# Events

## Overview

User Behavior Collector does not use a traditional message broker for event consumption. Instead, it reads Janus Kafka events that have been pre-materialized as Parquet files on HDFS/GCS under the path `/user/kafka/source=janus-all/ds=<date>/hour=<hour>/`. The job advances a file-pointer cursor (stored in the `key-value-store` table as `next-kafka-file`) to track which files have been processed. Processed data is written as intermediate result files to HDFS and persisted to PostgreSQL; no outbound Kafka or message-bus events are published by this service.

## Published Events

> No evidence found in codebase. This service does not publish events to a message broker. Audience data is published via REST API calls to the Audience Management Service and file upload to Cerebro HDFS — not via a topic or queue.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `janus-all` (HDFS/GCS Parquet files) | `dealView` | `SparkJob.getDealViewEventRDD()` | Persists `DealViewInfo` records to `deal_view_notification` DB |
| `janus-all` (HDFS/GCS Parquet files) | `dealPurchase` | `SparkJob.getPurchaseEventRDD()` | Persists `DealPurchaseInfo` records to `deal_view_notification` DB |
| `janus-all` (HDFS/GCS Parquet files) | `search` (mobile: `rawEvent=GRP1`) | `SparkJob.getUserSearchRDD()` | Persists `UserSearchInfo` records to HDFS and DB |
| `janus-all` (HDFS/GCS Parquet files) | `search` (web: `rawEvent=bh-impression`) | `SparkJob.getUserSearchRDD()` | Persists `UserSearchInfo` records to HDFS and DB |
| `janus-all` (HDFS/GCS Parquet files) | `userDealRating` | `SparkJob.getUserRatingData()` | Persists `UserRatingData` records to HDFS |
| `janus-all` (HDFS/GCS Parquet files) | `emailOpenHeader` | `SparkJob.getUserEmailOpenData()` | Persists `EmailOpenInfo` records; channel must be `targeted_deal` |

### `dealView` Detail

- **Topic**: `/user/kafka/source=janus-all/` (HDFS/GCS Parquet)
- **Handler**: Spark pipeline filters events where `event == "dealView"`, `dealUUID != null`, and `dealStatus != null`
- **Idempotency**: File-pointer cursor prevents double-processing; de-duplication by `(bcookie, dealUUID)` key
- **Error handling**: Null/malformed records are filtered out via `.filter(pair -> pair != null)`; partial files (last file) are skipped
- **Processing order**: Unordered (parallel Spark RDD processing)

### `dealPurchase` Detail

- **Topic**: `/user/kafka/source=janus-all/` (HDFS/GCS Parquet)
- **Handler**: Spark pipeline filters events where `event == "dealPurchase"` and `dealUUID != null`
- **Idempotency**: Controlled by file-pointer advancement; skipViewPurchase flag disables processing post-migration to realtime pipeline
- **Error handling**: Malformed events filtered; job continues on parse errors
- **Processing order**: Unordered

### `emailOpenHeader` Detail

- **Topic**: `/user/kafka/source=janus-all/` (HDFS/GCS Parquet)
- **Handler**: Spark pipeline filters events where `event == "emailOpenHeader"`, `medium == "email"`, `channel == "targeted_deal"`, `dealList != null`, and `campaign != null`
- **Idempotency**: Retention-based cleanup via `clearOldEmailOpen()` in `AppDataConnection`
- **Error handling**: Null results filtered from flatMap
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase. Failed Spark processing does not use a DLQ; job failure triggers email alerts and PagerDuty pages. The file pointer is manually advanced if a file range must be skipped.
