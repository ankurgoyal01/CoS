---
service: "push-client-proxy"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for push-client-proxy.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Email Send Request](email-send-request.md) | synchronous | `POST /email/send-email` from Bloomreach | Validates, rate-limits, and injects an outbound email via SMTP; returns sync response |
| [Delivery Status Callback](delivery-status-callback.md) | asynchronous | `msys_delivery` Kafka event from the Kafka broker | Correlates delivery-status CSV events with cached Redis metadata and POSTs callbacks to downstream HTTP |
| [Audience Patch](audience-patch.md) | synchronous | `PATCH /audiences/{audienceId}` from Audience Management Service | Rate-limits, validates, and applies audience membership changes to Redis and PostgreSQL |
| [Async Email Send](async-email-send.md) | asynchronous | `email-send-topic` Kafka message | Processes batches of email send requests from Kafka, checks subscriptions, sends via SMTP, persists outcomes, and retries failures |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The **Email Send Request** and **Delivery Status Callback** flows together form the full email lifecycle documented in the architecture dynamic view `dynamic-email-request-flow`.
- The **Audience Patch** flow is documented in the architecture dynamic view `dynamic-audience-patch-flow`.
- The **Async Email Send** flow is an internal queue-driven retry pathway not covered by a standalone architecture dynamic view.
