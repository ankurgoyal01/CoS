---
service: "garvis"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [pubsub, rq, webhook]
---

# Events

## Overview

Garvis uses two async messaging mechanisms: Google Cloud Pub/Sub for inbound Google Chat events, and Redis-backed RQ (Redis Queue) for internal background job dispatch. The `continuumJarvisBot` container subscribes to a Pub/Sub topic to receive all Google Chat messages directed at the bot. It then enqueues jobs onto Redis RQ queues for the `continuumJarvisWorker` container to execute asynchronously. JIRA webhooks are also consumed by the `continuumJarvisWebApp` container to trigger change management workflows.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| RQ default queue (Redis) | `background-job` | Bot command handler or web flow enqueues a job | Job function reference, arguments, job ID |
| RQ scheduled queue (Redis) | `scheduled-job` | RQ Scheduler fires at configured interval | Job function reference, schedule config |

### background-job Detail

- **Topic**: RQ default queue (Redis key: `rq:queue:default` or named queues)
- **Trigger**: A bot plugin handler or web controller enqueues work that should not block the HTTP or Pub/Sub response path
- **Payload**: Serialized Python callable reference and arguments (RQ job envelope)
- **Consumers**: `continuumJarvisWorker` (`workerRqWorker` component)
- **Guarantees**: at-least-once (RQ retry semantics; failed jobs move to the failed queue)

### scheduled-job Detail

- **Topic**: RQ Scheduler queue (Redis)
- **Trigger**: `workerScheduler` fires jobs at configured recurring intervals (e.g., on-call rotation checks, periodic notifications)
- **Payload**: Serialized Python callable reference and schedule metadata
- **Consumers**: `continuumJarvisWorker` (`workerRqWorker` component)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Google Cloud Pub/Sub topic | `google-chat-message` | `botPubSubSubscriber` → `botCommandRouter` | Routes to plugin, may enqueue RQ job, may call Google Chat API or JIRA |
| JIRA webhook (HTTP POST) | `jira-issue-event` | `webHttpControllers` in `continuumJarvisWebApp` | Updates change or incident state in PostgreSQL, may notify Google Chat |

### google-chat-message Detail

- **Topic**: Google Cloud Pub/Sub topic (subscription managed via `google-cloud-pubsub` 2.34.0 SDK)
- **Handler**: `botPubSubSubscriber` receives the raw Pub/Sub message; `botCommandRouter` parses the embedded Google Chat event payload and dispatches to `botPluginHandlers`
- **Idempotency**: Not guaranteed at the Pub/Sub layer; plugin handlers are responsible for deduplication where required
- **Error handling**: Pub/Sub provides automatic retry with exponential backoff; unacknowledged messages are redelivered up to the subscription's ack deadline
- **Processing order**: Unordered (Google Cloud Pub/Sub does not guarantee strict ordering for standard subscriptions)

### jira-issue-event Detail

- **Topic**: JIRA webhook delivered via HTTP POST to Garvis web endpoint
- **Handler**: `webHttpControllers` in `continuumJarvisWebApp` receives and processes the JIRA event payload
- **Idempotency**: Dependent on JIRA event deduplication via issue ID
- **Error handling**: HTTP 2xx response acknowledges the webhook; JIRA retries on non-2xx responses
- **Processing order**: Unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| RQ failed queue (Redis) | RQ default / named queues | Until manually cleared or TTL expiry | Visible in `/django-rq/` dashboard |

> Failed RQ jobs are moved to the RQ failed queue and surfaced in the `continuumJarvisWebApp` RQ dashboard at `/django-rq/`.
