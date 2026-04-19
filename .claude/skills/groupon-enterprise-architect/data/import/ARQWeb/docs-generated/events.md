---
service: "ARQWeb"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

ARQWeb does not use a traditional message broker (Kafka, RabbitMQ, SQS, etc.) for async messaging. Asynchronous work is handled through an internal job queue persisted in PostgreSQL (`continuumArqPostgres`) and executed by the ARQ Worker (`continuumArqWorker`). The worker delivers outbound webhook notifications to registered external consumers via HTTPS POST. There are no inbound event subscriptions from external message topics.

## Published Events

> This service does not publish events to a message broker. Outbound async notifications are delivered as webhook HTTP POST calls by the `continuumArqWorker` to `externalWebhookConsumers`.

### Webhook Notifications (Outbound)

- **Mechanism**: HTTPS POST
- **Trigger**: Job handlers in `continuumArqWorker` process queued webhook jobs from PostgreSQL
- **Target**: Registered external webhook consumer URLs
- **Payload**: Access request state change notifications (specific payload schema not discoverable from architecture model)
- **Guarantees**: At-least-once delivery (job queue with retries, as evidenced by retry and timeout protection in `arqWorkerCronLoop`)

## Consumed Events

> This service does not consume events from a message broker. All inbound triggers are HTTP requests (web UI or API) or internal cron schedule evaluation by the `arqWorkerCronLoop`.

## Dead Letter Queues

> Not applicable. Error handling for failed jobs is managed within the PostgreSQL-backed job queue (retry logic in `arqWorkerCronLoop` with timeout protection).
