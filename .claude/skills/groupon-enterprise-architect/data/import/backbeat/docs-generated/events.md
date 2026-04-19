---
service: "backbeat"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [sidekiq, redis]
---

# Events

## Overview

Backbeat does not use a traditional publish/subscribe message broker (e.g. Kafka or RabbitMQ). Asynchronous work is coordinated internally through Sidekiq-backed Redis queues. The API Runtime enqueues job metadata into Redis; the Worker Runtime dequeues and executes those jobs. External notifications take the form of outbound HTTP callbacks rather than published events.

## Published Events

> This service does not publish events to an external message bus. Asynchronous coordination uses Sidekiq queues backed by `continuumBackbeatRedis`.

## Consumed Events

> This service does not consume events from an external message bus. Work items are delivered via Sidekiq job queues.

## Internal Job Queues (Sidekiq / Redis)

| Queue | Producer | Consumer | Purpose |
|-------|----------|---------|---------|
| Sidekiq default queue (Redis) | `continuumBackbeatApiRuntime` (`bbWebApi`) | `continuumBackbeatWorkerRuntime` (`bbAsyncWorker`) | Carries asynchronous workflow event execution jobs |
| Scheduled/retry queue (Redis) | `bbScheduler` | `bbAsyncWorker` | Carries delayed and retry workflow events |
| Daily report queue (Redis) | Cron/Sidekiq scheduler | `bbDailyActivityReporter` | Triggers daily workflow activity email generation |

### Async Workflow Event Job Detail

- **Queue backend**: `continuumBackbeatRedis`
- **Producer**: `continuumBackbeatApiRuntime` — enqueues job metadata after creating workflow state
- **Consumer**: `bbAsyncWorker` — deserializes node references and dispatches to `bbWorkflowEvents`
- **Side effects**: state transitions via `bbStateManager`, HTTP callback via `bbClientAdapter`, metric emission via `bbMetricsReporter`
- **Error handling**: Sidekiq built-in retry with backoff; failed jobs surface through Sidekiq stats endpoint

## Dead Letter Queues

> No evidence found of a named dead letter queue. Sidekiq retry exhaustion behavior — confirm with service owners.
