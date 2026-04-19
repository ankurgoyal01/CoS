---
service: "sem-gcp-pipelines"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["mbus", "stomp"]
---

# Events

## Overview

sem-gcp-pipelines uses the internal Groupon Message Bus (STOMP protocol) to publish keyword submission messages. This is the sole async messaging integration in the service. The `SubmitKeywords` Spark job reads pre-computed keyword data from GCS (Parquet format, Hive-partitioned by deal, country, and region), groups keywords by deal and country, and publishes one message per deal-country combination to the configured Message Bus queue. The STOMP connection uses persistent message delivery (`persistent: true`) with a heartbeat setting of 60 seconds receive / 20 seconds send.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `MESSAGE_BUS.QUEUE_NAME` (configured per environment) | Keyword Submission | Scheduled Spark job execution on Dataproc (triggered by Airflow DAG) | `deal_id`, `keywords`, `user`, `country` |

### Keyword Submission Detail

- **Topic**: `MESSAGE_BUS.QUEUE_NAME` — queue name is loaded from the job params JSON file at runtime (`options['MESSAGE_BUS']['QUEUE_NAME']`)
- **Trigger**: Airflow DAG schedules the `submit_keywords` PySpark job on Dataproc; the job reads final keyword data from GCS and publishes per-deal messages
- **Payload**:
  ```json
  {
    "deal_id": "<deal uuid>",
    "keywords": ["<keyword1>", "<keyword2>", "..."],
    "user": "<user_name>",
    "country": "<country code>"
  }
  ```
- **Consumers**: Internal keyword management services (downstream consumers tracked in the central architecture model)
- **Guarantees**: at-least-once — STOMP `persistent: true` header ensures message durability; no deduplication logic present in the publisher

## Consumed Events

> No evidence found in codebase.

sem-gcp-pipelines does not consume any async events or subscribe to any Message Bus queues. All pipeline triggers are schedule-based (Airflow cron) or manual (Airflow UI / API).

## Dead Letter Queues

> No evidence found in codebase.

No dead-letter queue configuration is defined in the codebase. Failed keyword publish operations cause the Spark job to fail and rely on Airflow retry logic for re-execution.
