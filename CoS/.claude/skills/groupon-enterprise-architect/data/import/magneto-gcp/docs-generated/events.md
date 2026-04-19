---
service: "magneto-gcp"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

magneto-gcp does not use a message broker (Kafka, Pub/Sub, RabbitMQ, SQS, or similar) for inter-service communication. All pipeline coordination is internal to Apache Airflow: tasks communicate via Airflow XCom (in-process task metadata), Airflow Variables, and shared GCS paths. The service does use Airflow callback hooks (`trigger_event` / `resolve_event` from `preutils.Impl`) on DAG task failure and success — these are internal Airflow alerting hooks, not publishable events. Audit failure notifications are sent by email to `dnd-ingestion@groupon.com` via SMTP.

## Published Events

> No evidence found in codebase. This service does not publish async events to any external message bus.

## Consumed Events

> No evidence found in codebase. This service does not consume events from any external message bus.

## Dead Letter Queues

> Not applicable — no message broker integration.

---

> This service does not publish or consume async events via a message broker. All inter-task coordination uses Apache Airflow XCom and GCS-backed YAML config files. Operational alerts are delivered via Airflow callbacks and SMTP email.
