---
service: "refresh-api-v2"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [tableau-webhooks]
---

# Events

## Overview

Refresh API V2 does not use a traditional message broker (Kafka, RabbitMQ, SQS). Instead, it consumes Tableau webhook events delivered over HTTP POST to dedicated endpoints. These webhooks are pushed directly by Tableau Server when events such as datasource or workbook refreshes complete. The service does not publish events to any downstream messaging system; job results are persisted to Postgres and polled by the Optimus Prime UI via REST.

## Published Events

> No evidence found in codebase of published async events to a message broker.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `POST /api/v2/events/tableau` | `WebhookEvent` | Tableau webhook handler | Triggers extract refresh job via Quartz scheduler |
| `POST /api/v2/events/analytics` | `WebhookEvent` | Analytics webhook handler | Triggers extract refresh job via Quartz scheduler |

### WebhookEvent Detail

- **Topic**: HTTP POST delivered to `/api/v2/events/tableau` or `/api/v2/events/analytics`
- **Handler**: Dropwizard JAX-RS resource (`API Resources` component) → `Refresh & Publish Services` component → Quartz scheduler enqueue
- **Payload fields**: `resource` (string), `event_type` (string), `resource_name` (string), `site_luid` (UUID), `resource_luid` (UUID), `created_at` (ISO 8601 datetime), `env` (optional string)
- **Idempotency**: No explicit deduplication; concurrent execution is controlled by `@DisallowConcurrentExecution` on Quartz jobs per job ID
- **Error handling**: HTTP 500 returned on processing error; no retry or DLQ mechanism configured at the HTTP layer
- **Processing order**: Unordered; each webhook enqueues an independent Quartz job

## Dead Letter Queues

> No evidence found in codebase. No message broker DLQ is configured. Failures are logged to Postgres job records and surfaced via Opsgenie alerts.
