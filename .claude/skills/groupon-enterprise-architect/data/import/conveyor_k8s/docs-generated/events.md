---
service: "conveyor_k8s"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Conveyor K8s does not use a traditional message bus (Kafka, RabbitMQ, SQS, Pub/Sub). Deployment observability events are sent directly to **Wavefront** via its REST API (`POST /api/v2/event`, `POST /api/v2/event/{id}/close`) during cluster promotion. These Wavefront events mark the start and end of a promotion window for correlation with metrics dashboards. No topics or queues are consumed.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Wavefront `/api/v2/event` | Deployment event | Cluster promotion start | `name`, `startTime`, `endTime`, `tags`, `annotations` |

### Wavefront Deployment Event Detail

- **Topic**: Wavefront REST API endpoint (`/api/v2/event`)
- **Trigger**: Cluster promotion pipeline begins — invoked by `wavefront create-event` CLI binary
- **Payload**: Wavefront `Event` JSON object containing event name, timestamps, and environment tags
- **Consumers**: Wavefront dashboards for metrics correlation during promotions
- **Guarantees**: At-most-once (HTTP POST with no retry — failure is logged but does not block promotion)

## Consumed Events

> This service does not consume any async events from a message bus.

## Dead Letter Queues

> Not applicable. No message bus DLQs are configured.
