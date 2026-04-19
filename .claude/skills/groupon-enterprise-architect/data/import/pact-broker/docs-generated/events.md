---
service: "pact-broker"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [webhooks]
---

# Events

## Overview

Pact Broker does not use a traditional async message broker (e.g., Kafka, RabbitMQ, or Pub/Sub). Instead, it delivers lifecycle notifications through configurable outbound HTTP webhooks. Webhooks are triggered by internal pact events (such as a new pact being published or a verification result being recorded) and dispatched by the `continuumPactBrokerWebhookDispatcher` component to allow-listed external hosts.

## Published Events

> No evidence found in codebase. Pact Broker does not publish events to a message bus or queue. It delivers outbound HTTP webhook callbacks instead (see webhook dispatch flow in [Flows](flows/index.md)).

## Consumed Events

> No evidence found in codebase. Pact Broker does not consume events from a message bus or queue. All triggers arrive via synchronous HTTP API calls.

## Dead Letter Queues

> Not applicable. No message broker or DLQ configuration exists. Webhook retry behavior is managed internally by the upstream pact-foundation/pact-broker application.

---

## Webhook Dispatch (Outbound Callbacks)

While not a traditional event system, the Webhook Dispatcher functions as an outbound event delivery mechanism.

### Webhook Triggers

| Internal Event | Target Hosts | Purpose |
|----------------|-------------|---------|
| Pact published (new consumer version) | `github.groupondev.com`, `github.com` | Notify CI pipelines to trigger provider verification builds |
| Verification result recorded | `github.groupondev.com`, `github.com` | Notify CI pipelines of verification outcomes |

### Webhook Allow-list

Outbound webhook targets are restricted by the `PACT_BROKER_WEBHOOK_HOST_WHITELIST` environment variable:
- `github.groupondev.com` — Groupon GitHub Enterprise (internal CI)
- `github.com` — GitHub.com (public CI)

Webhook configurations are stored in the PostgreSQL database and managed via the `/webhooks` API endpoints.
