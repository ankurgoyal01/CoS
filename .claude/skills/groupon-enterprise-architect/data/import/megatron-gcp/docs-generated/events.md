---
service: "megatron-gcp"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Megatron GCP does not publish or consume asynchronous events via a message broker (Kafka, Pub/Sub, RabbitMQ, etc.). All inter-task communication is managed through Apache Airflow's XCom mechanism and Airflow task dependencies within the DAG execution graph. Failure and success signals are delivered to Slack via the `preutils.Impl` callbacks (`trigger_event`, `resolve_event`) bound to each DAG's `on_failure_callback` and `on_success_callback` hooks.

## Published Events

> No evidence found in codebase. This service does not publish events to any message broker or event bus.

## Consumed Events

> No evidence found in codebase. This service does not consume events from any message broker or event bus.

## Airflow Callback Signals

Although not traditional async events, the following callback patterns act as operational signals:

| Callback | Type | Trigger | Destination |
|----------|------|---------|-------------|
| `trigger_event` | failure notification | Any task `on_failure_callback` | Slack `#dnd-ingestion-ops` via `preutils.Impl` |
| `resolve_event` | success notification | DAG-level `on_success_callback` | Slack `#dnd-ingestion-ops` via `preutils.Impl` |

## Dead Letter Queues

> No evidence found in codebase. Failed pipeline runs are tracked in the `etl_process_status` table (status set to `FAILED`) and retried by Airflow's built-in retry mechanism with exponential backoff on the `check_status` task.
