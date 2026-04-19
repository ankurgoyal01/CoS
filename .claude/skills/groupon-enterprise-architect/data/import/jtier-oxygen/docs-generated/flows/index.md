---
service: "jtier-oxygen"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for JTier Oxygen.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Broadcast Lifecycle](broadcast-lifecycle.md) | synchronous + asynchronous | API call (`POST /broadcasts`, `PUT /broadcasts/{name}/running`) | Create, start, run, and stop a named message-bus broadcast; tracks message fanout and iteration metrics |
| [Greeting CRUD](greeting-crud.md) | synchronous | API call (`POST /greetings`, `GET /greetings/{name}`) | Store and retrieve greeting key-value pairs in Postgres |
| [MessageBus Roundtrip](messagebus-roundtrip.md) | synchronous | API call (`POST /messagebus/mass-roundtrip/{count}/{size}`) | Publish a batch of messages to the queue and consume them back, measuring throughput |
| [Redis Key-Value](redis-key-value.md) | synchronous | API call (`POST /redis`, `GET /redis/{key}`) | Store and retrieve arbitrary key-value pairs in Redis |
| [Scheduled Job Execution](scheduled-job-execution.md) | scheduled | Quartz cron trigger | Run `EverywhereJob` (every instance) and `ExclusiveJob` (one designated instance) on cron schedule |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The broadcast lifecycle flow spans `continuumOxygenService` and the shared `messageBus` infrastructure, as captured in the architecture dynamic view `dynamic-oxygen-runtime-flow`. All other flows are internal to the service and its owned data stores.

See [Architecture Context](../architecture-context.md) for C4 relationship details.
