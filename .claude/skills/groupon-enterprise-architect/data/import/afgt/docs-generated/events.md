---
service: "afgt"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

AFGT does not use a message broker (Kafka, RabbitMQ, SQS, Pub/Sub, or similar) for communication. All inter-pipeline coordination is handled through Apache Airflow DAG-level mechanisms: `PythonSensor` for upstream completion checks and `TriggerDagRunOperator` for downstream triggering. Notifications are delivered via Google Chat webhook and email.

## Published Events

> No evidence found — AFGT does not publish messages to any async messaging system.

AFGT does trigger the following Airflow DAG runs as a form of downstream notification, but these are direct Airflow calls, not message-bus events:

| Trigger Target | Mechanism | Trigger Condition | Notes |
|----------------|-----------|------------------|-------|
| `rma-gmp-wbr-load` | `TriggerDagRunOperator` | After `hive_load` task succeeds | Triggers downstream GMP/WBR Hive load DAG |

## Consumed Events

> No evidence found — AFGT does not consume messages from any async messaging system.

AFGT does poll the following upstream DAG completion states using `PythonSensor` before starting its own execution:

| Upstream DAG | Sensor Task | Polling Method | Condition |
|--------------|-------------|---------------|-----------|
| `DLY_OGP_FINANCIAL_varRUNDATE_0003` | `ogp_check` | `CheckRuns.check_daily_completion` | Daily completion confirmed |
| `go_segmentation` (task: `end`) | `go_segment_check` | `CheckRunsLegacy.monitoring_task` | Task status `success` within time scope |

## Dead Letter Queues

> Not applicable — no message broker in use. Retry and failure handling are managed by Airflow task retry configuration (`retries: 1`, `retry_delay: 1800s`) and the `on_failure_callback` function which posts alerts to the Google Chat webhook and triggers the `trigger_event` callable.
