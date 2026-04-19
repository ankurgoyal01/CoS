---
service: "deal-alerts"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Deal Alerts does not use a traditional message broker (Kafka, RabbitMQ, SQS, etc.) for asynchronous event processing. Instead, the system uses a database-driven event model: n8n workflows poll the PostgreSQL database on schedules (or react to webhooks) to discover new alerts and pending notifications, then process them in batch. Twilio delivery callbacks arrive as HTTP webhooks handled by n8n workflows.

## Published Events

> This service does not publish events to a message broker. Alert state changes are persisted directly to PostgreSQL tables and consumed by n8n workflows via scheduled queries.

## Consumed Events

| Source | Type | Handler | Side Effects |
|--------|------|---------|-------------|
| Twilio delivery webhooks | SMS status callback | SMS Notifications Sender workflow | Updates notification_status_history with delivery status, error codes, and timestamps |
| Twilio inbound SMS | Reply webhook | SMS Notifications Sender workflow | Inserts notification_replies with message, direction, opt-out type, and command parsing |

## Dead Letter Queues

> No DLQ infrastructure. Failed actions are tracked in the `actions` table with `error_message` and `retry_count` columns. Failed notifications are tracked via `notification_status_history`. Error aggregation is exposed through the Logs API Router.
