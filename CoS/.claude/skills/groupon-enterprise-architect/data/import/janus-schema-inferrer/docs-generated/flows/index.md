---
service: "janus-schema-inferrer"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Janus Schema Inferrer.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Kafka Schema Inference](kafka-schema-inference.md) | scheduled | Hourly CronJob (`0 * * * *`) | Samples Kafka topics, extracts event payloads, infers schemas, and persists to Janus |
| [MBus Schema Inference](mbus-schema-inference.md) | scheduled | Hourly CronJob (`0 * * * *`) | Samples MBus topics, extracts event payloads, infers schemas, and persists to Janus |
| [Schema Normalization and Merging](schema-normalization-and-merging.md) | event-driven | Triggered per-topic after sampling | Normalizes Spark-inferred schema, diffs against stored schema, and merges via union |
| [Application Bootstrap](application-bootstrap.md) | synchronous | CronJob pod startup | Selects inferrer mode, initializes Janus client, creates health flag, and launches inference |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

Both the Kafka and MBus inference flows interact with `continuumJanusWebCloudService` for rules retrieval and schema persistence. These interactions are documented in the Structurizr dynamic views:

- Kafka flow: `dynamic-janus-schema-inferrer-kafka-flow`
- MBus flow: `dynamic-janus-schema-inferrer-mbus-flow`

See [Integrations](../integrations.md) for dependency details and [Architecture Context](../architecture-context.md) for C4 component relationships.
