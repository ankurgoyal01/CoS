---
service: "mds-feed-api"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The Marketing Feed Service uses the Groupon Message Bus (Mbus, JMS-based) for asynchronous event publishing. When a Spark feed generation batch transitions to a terminal successful state, the service publishes a `GeneratedFeedDto` message to the `mds-feed-publishing` Mbus destination. This notifies downstream systems that a new feed file is available for consumption. The service does not consume any inbound async events; all inbound triggers are via HTTP.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `mds-feed-publishing` | `GeneratedFeedDto` | Batch status transitions to successful (polled by `CheckBatchStateJob`) | `clientId`, `url` |

### GeneratedFeedDto Detail

- **Topic**: `mds-feed-publishing` (Mbus destination ID, configured via `mbus.destinations[0]`)
- **Trigger**: The `CheckBatchStateJob` Quartz cron (runs every minute) detects that a Spark batch has completed successfully and invokes `DispatchService`, which writes a message via `MbusWriter<GeneratedFeedDto>`
- **Payload**: Contains at minimum `clientId` (the feed's client identifier) and `url` (the GCS/dispatch URL of the generated feed file); full schema is `com.groupon.mars.mdsfeedapi.dto.GeneratedFeedDto`
- **Consumers**: Downstream marketing systems or affiliate integrations that subscribe to this Mbus topic to detect available feed files
- **Guarantees**: at-least-once (JMS topic semantics via Mbus)

## Consumed Events

> No evidence found in codebase. The service does not consume any inbound async events. All triggering is done via HTTP REST API or scheduled Quartz jobs.

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration is visible in the repository. Publishing failures throw `MbusPublishingException`.
