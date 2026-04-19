---
service: "img-service-primer"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Image Service Primer participates in async messaging as a consumer only. It subscribes to video transformation update events from the Groupon internal message bus (JMS/STOMP). These events trigger the video transformation pipeline — the `VideoUpdateListener` receives the event and hands off to `VideoTransformer`, which downloads source media, runs ffmpeg processing, and uploads the result to S3. The service does not publish any events to the message bus.

## Published Events

> No evidence found in codebase of any events published by this service to the message bus.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `unknownVideoTransformationTopic` (stub) | Video transformation update | `VideoUpdateListener` | Runs video transformation pipeline; writes state to MySQL; uploads to S3 |

### Video Transformation Update Detail

- **Topic**: Video transformation topic (referenced as a stub in the architecture DSL — exact topic name not confirmed in source files)
- **Handler**: `VideoUpdateListener` — receives event payload and delegates to `VideoTransformer`
- **Processing steps**: `VideoUpdateListener` -> `VideoTransformer` -> `VideoDao` (reads/updates MySQL) -> `S3VideoUploader` (uploads artifact)
- **Idempotency**: No evidence found in codebase of explicit idempotency controls; transformation records in MySQL track state.
- **Error handling**: No evidence found in codebase of a dead-letter queue configuration.
- **Processing order**: Unordered — events are processed as received

## Dead Letter Queues

> No evidence found in codebase of dead-letter queue configuration.
