---
service: "selfsetup-fd"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mysql-queue]
---

# Events

## Overview

selfsetup-fd does not use an external message broker (no Kafka, RabbitMQ, SQS, or similar). Async processing is implemented via a **MySQL-backed job queue** polled by scheduled cron jobs. Setup requests are enqueued by the web layer and dequeued/processed by `ssuCronJobs` on a schedule. There are no published or consumed broker-level events.

## Published Events

> No evidence found of broker-level published events. Async work is enqueued into the MySQL queue table via `ssuQueueRepository`.

## Consumed Events

> No evidence found of broker-level consumed events. The `ssuCronJobs` component polls the MySQL queue table directly via `ssuQueueRepository` rather than subscribing to an external topic or queue service.

## Internal Queue (MySQL-backed)

| Queue / Table | Producer | Consumer | Purpose |
|---------------|----------|----------|---------|
| MySQL queue table | `ssuWebControllers` (via `ssuQueueRepository`) | `ssuCronJobs` (via `ssuQueueRepository`) | Stores pending BT setup jobs for async processing |

### Queue Job Detail

- **Enqueued by**: `ssuWebControllers` after opportunity validation passes
- **Processed by**: `ssuCronJobs` on a scheduled cron interval
- **Processing steps**: fetch merchant identifiers from Salesforce, call Booking Tool API to create/configure BT instance, update job status in MySQL
- **Idempotency**: No evidence found of explicit idempotency keys; retry behaviour is cron-driven
- **Error handling**: Failed jobs remain in the queue; no dead-letter table evidenced in the inventory

## Dead Letter Queues

> No evidence found of a dead-letter queue or DLQ pattern.
