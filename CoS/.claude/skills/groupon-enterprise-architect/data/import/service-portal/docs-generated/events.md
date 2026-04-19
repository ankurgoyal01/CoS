---
service: "service-portal"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [github-webhooks, sidekiq]
---

# Events

## Overview

Service Portal does not use a traditional message broker (no Kafka, RabbitMQ, or SQS). Asynchronous work is driven by two mechanisms: inbound GitHub Enterprise webhook events consumed via the `/processor` HTTP endpoint, and internally scheduled Sidekiq jobs managed by sidekiq-cron. Sidekiq jobs write outcomes (check results, cost records, notifications) directly to MySQL and trigger outbound calls to Google Chat.

## Published Events

> Not applicable. Service Portal does not publish events to an external message bus or topic. Outcomes are written to `continuumServicePortalDb` and notifications are sent synchronously to Google Chat via the `google-apis-chat_v1` client.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `/processor` (HTTP) | GitHub push event | GitHub Webhook Processor (Rails controller) | Enqueues `GitHubSyncWorker` job in Redis/Sidekiq |
| `/processor` (HTTP) | GitHub pull_request event | GitHub Webhook Processor (Rails controller) | Enqueues `GitHubSyncWorker` job in Redis/Sidekiq |
| Sidekiq queue (internal) | Scheduled check run | Sidekiq-Cron scheduled job | Executes service checks; writes results to `continuumServicePortalDb`; sends Google Chat alerts on failures |
| Sidekiq queue (internal) | Cost tracking run | Sidekiq-Cron scheduled job | Collects cost data; writes to `continuumServicePortalDb`; sends Google Chat alerts if thresholds exceeded |
| Sidekiq queue (internal) | Inactivity report run | Sidekiq-Cron scheduled job | Identifies inactive services; writes report data to `continuumServicePortalDb` |
| Sidekiq queue (internal) | GitHub repository sync | Enqueued by webhook processor | Fetches repo metadata from GitHub Enterprise REST API; updates `continuumServicePortalDb` |

### GitHub push event Detail

- **Topic**: `/processor` HTTP endpoint
- **Handler**: Rails webhook processor controller; verifies HMAC signature (`X-Hub-Signature-256`) before processing
- **Idempotency**: Webhook events may be re-delivered by GitHub; the sync worker is expected to produce the same outcome on repeated runs (upsert semantics)
- **Error handling**: Invalid HMAC signatures are rejected with HTTP 401. Processing errors result in failed Sidekiq jobs; Sidekiq retries with backoff
- **Processing order**: Unordered (each event is independent)

### GitHub pull_request event Detail

- **Topic**: `/processor` HTTP endpoint
- **Handler**: Rails webhook processor controller; HMAC verification applied
- **Idempotency**: Upsert semantics in sync worker
- **Error handling**: Same as push event — invalid signatures rejected; Sidekiq retry on failure
- **Processing order**: Unordered

### Scheduled check run Detail

- **Topic**: Sidekiq internal queue (configured via sidekiq-cron)
- **Handler**: Scheduled check runner worker — iterates registered services and evaluates each defined check
- **Idempotency**: Check results are overwritten on each run; repeated runs are safe
- **Error handling**: Individual check failures are recorded per service; worker-level failures trigger Sidekiq retry
- **Processing order**: Unordered across services

## Dead Letter Queues

> No evidence found for a configured dead-letter queue. Failed Sidekiq jobs follow standard Sidekiq retry-then-dead-set behavior (exhausted retries land in the Sidekiq dead set in Redis).
