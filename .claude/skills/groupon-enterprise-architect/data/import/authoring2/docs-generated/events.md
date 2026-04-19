---
service: "authoring2"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [activemq]
---

# Events

## Overview

Authoring2 uses ActiveMQ (JMS) for asynchronous processing of bulk taxonomy operations and snapshot generation. The ActiveMQ broker runs as a Docker sidecar container alongside the application pod on the same host at `localhost:61616`. The queue name is `Authoring2`. Messages are dispatched by REST facade classes (JMS producers) and consumed by `BulkQueueListener` (JMS consumer). Each message carries a `OPERATION_TYPE` string property that determines which workflow the consumer executes.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `Authoring2` | `SNAPSHOT` | `POST /snapshots/create` — user requests a full taxonomy snapshot | `id` (snapshot numeric ID) |
| `Authoring2` | `UPDATE_ATTRIBUTE_BULK` | `POST /bulk/edit-attributes` — user submits attribute CSV update | `guid` (bulk job GUID) |
| `Authoring2` | `CREATE_CATEGORIES_BULK` | `POST /bulk/create-categories` — user submits category creation CSV | `guid` (bulk job GUID) |
| `Authoring2` | `UPDATE_CATEGORIES_AND_HEADERS_BULK` | `POST /bulk/update-categories-and-headers` — user submits category+header CSV | `guid` (bulk job GUID) |
| `Authoring2` | `UPDATE_TRANSLATIONS_BULK` | `POST /bulk/translations` — user submits locale translation map | `guid` (bulk job GUID) |
| `Authoring2` | `CREATE_UPDATE_RELATIONSHIPS` | `POST /bulk/relationships` — user submits relationship CSV | `guid` (bulk job GUID) |

### SNAPSHOT Detail

- **Topic**: `Authoring2`
- **Trigger**: REST call to `POST /snapshots/create` when no snapshot is currently `PENDING`
- **Payload**: JSON-serialized `SnapshotQueue` object containing `id` (the newly created snapshot database row ID)
- **JMS property**: `OPERATION_TYPE = SNAPSHOT`
- **Consumers**: `BulkQueueListener` within the same Authoring2 process
- **Guarantees**: at-least-once (JMS `CLIENT_ACKNOWLEDGE`)

### Bulk Operation Detail (all bulk event types)

- **Topic**: `Authoring2`
- **Trigger**: REST calls to the `/bulk/*` ingress endpoints
- **Payload**: JSON-serialized `BulkCSV` or `BulkCSVTranslations` object containing the bulk job `guid` and serialized input data
- **JMS property**: `OPERATION_TYPE` = one of `UPDATE_ATTRIBUTE_BULK`, `CREATE_CATEGORIES_BULK`, `UPDATE_CATEGORIES_AND_HEADERS_BULK`, `UPDATE_TRANSLATIONS_BULK`, `CREATE_UPDATE_RELATIONSHIPS`
- **Consumers**: `BulkQueueListener` within the same Authoring2 process
- **Guarantees**: at-least-once (JMS `CLIENT_ACKNOWLEDGE`)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `Authoring2` | `SNAPSHOT` | `BulkQueueListener` | Generates full XML snapshot content, persists to `continuumAuthoring2Postgres`, sets snapshot status |
| `Authoring2` | `UPDATE_ATTRIBUTE_BULK` | `BulkQueueListener` | Applies attribute updates to categories in `continuumAuthoring2Postgres`, updates `Bulk` progress record |
| `Authoring2` | `CREATE_CATEGORIES_BULK` | `BulkQueueListener` | Creates categories in batch, updates `Bulk` progress record |
| `Authoring2` | `UPDATE_CATEGORIES_AND_HEADERS_BULK` | `BulkQueueListener` | Updates category names and header flags, updates `Bulk` progress record |
| `Authoring2` | `UPDATE_TRANSLATIONS_BULK` | `BulkQueueListener` | Applies locale translation changes to categories, updates `Bulk` progress record |
| `Authoring2` | `CREATE_UPDATE_RELATIONSHIPS` | `BulkQueueListener` | Creates or updates category relationships in batch, updates `Bulk` progress record |

### BulkQueueListener Detail

- **Topic**: `Authoring2`
- **Handler**: `com.groupon.authoring2.bulk.BulkQueueListener` — listens on `queue.name` (`Authoring2`), dispatches work based on the `OPERATION_TYPE` JMS message property
- **Idempotency**: Bulk jobs are guarded by a hashcode uniqueness check before enqueueing; re-submission of an already-existing hashcode raises an error
- **Error handling**: Errors are persisted to the `Bulk` result column in PostgreSQL; no separate DLQ configured
- **Processing order**: Unordered (one message at a time, but ordering not guaranteed across restarts)

## Dead Letter Queues

> No evidence found in codebase. No explicit dead-letter queue is configured in the ActiveMQ or application configuration.
