---
service: "liteLLM"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [langfuse, prometheus, smtp]
---

# Events

## Overview

LiteLLM does not use a traditional message bus (Kafka, RabbitMQ, SQS, or similar) for async event processing. Instead, it uses LiteLLM's built-in callback system to push observability and notification events synchronously or asynchronously to configured callback targets: Langfuse (prompt/response tracing), Prometheus (metrics), and SMTP (email alerts). These callbacks are configured via the `callbacks` setting in `config.yaml` and are not independently consumed by other services via a topic or queue.

## Published Events

> No evidence found in codebase of events published to a message bus topic or queue. Observability signals are emitted via the LiteLLM callback system to the targets listed below.

### Langfuse Callback

- **Target**: Langfuse service (`LANGFUSE_HOST`)
- **Trigger**: Every LLM request/response cycle
- **Payload**: Prompt, response, model name, latency, token counts, end-user ID
- **Purpose**: Prompt observability, debugging, and cost attribution in Langfuse UI
- **Guarantees**: At-least-once (callback-based, best effort)

### Prometheus Metrics Callback

- **Target**: `metricsStack` (Prometheus scrape endpoint)
- **Trigger**: Every LLM request/response cycle
- **Payload**: Token usage per model, cost per model, cost per end-user, request latency histograms
- **Purpose**: Autoscaling signals, alerting, and budget tracking
- **Guarantees**: At-least-once (in-process metrics emission)

### SMTP Email Callback

- **Target**: SMTP server (`SMTP_HOST`)
- **Trigger**: Configured alert conditions (e.g., budget exceeded, error thresholds)
- **Payload**: Notification email to configured recipients
- **Purpose**: Operational alerting via email
- **Guarantees**: At-most-once (SMTP delivery)

## Consumed Events

> No evidence found in codebase of this service consuming events from a message bus topic or queue. All inbound work arrives via synchronous HTTP requests.

## Dead Letter Queues

> Not applicable — no message bus is used.
