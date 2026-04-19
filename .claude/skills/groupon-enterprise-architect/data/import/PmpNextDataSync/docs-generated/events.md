---
service: "PmpNextDataSync"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

PmpNextDataSync does not publish or consume asynchronous events via a message broker (Kafka, RabbitMQ, Pub/Sub, etc.). The service is a scheduled batch pipeline: Airflow DAGs trigger Dataproc Spark jobs on a cron schedule, and all data movement occurs via JDBC reads from PostgreSQL and GCS writes to Hudi tables. There is no event-driven integration pattern in use.

## Published Events

> Not applicable. This service does not publish async events.

## Consumed Events

> Not applicable. This service does not consume async events.

## Dead Letter Queues

> Not applicable. No message queuing infrastructure is used.
