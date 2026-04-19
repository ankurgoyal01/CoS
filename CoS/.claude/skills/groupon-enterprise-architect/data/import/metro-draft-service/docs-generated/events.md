---
service: "metro-draft-service"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Metro Draft Service uses MBus (`continuumMetroDraftMessageBus`) as its async messaging layer. The service both publishes and consumes events. Published events include editor/recommendation actions and signed deal notifications. The service also consumes signed deal events to trigger downstream workflows. Event production is handled by the `continuumMetroDraftService_editorActionPublisher` and `continuumMetroDraftService_signedDealProducer` components; consumption is handled by `continuumMetroDraftService_signedDealListener`.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `continuumMetroDraftMessageBus` | `editor-action` | Deal lifecycle action or recommendation interaction recorded by History Event Service | deal ID, action type, actor, timestamp |
| `continuumMetroDraftMessageBus` | `signed-deal` | Deal is signed/finalized; emitted by Signed Deal Producer via History Event Service | deal ID, merchant ID, signed timestamp, deal metadata |
| `continuumMetroDraftMessageBus` | `deal-lifecycle` | Deal status transitions and publish events across the deal workflow | deal ID, previous status, new status, transition timestamp |

### editor-action Detail

- **Topic**: `continuumMetroDraftMessageBus`
- **Trigger**: History Event Service records a recommendation or editor action during deal creation, update, or status transition; calls Editor Action Publisher
- **Payload**: deal ID, action type (e.g., recommendation accepted/rejected), actor user ID, timestamp
- **Consumers**: Downstream recommendation and analytics services (tracked in central architecture model)
- **Guarantees**: at-least-once

### signed-deal Detail

- **Topic**: `continuumMetroDraftMessageBus`
- **Trigger**: A deal is finalized/signed; History Event Service delegates to Signed Deal Producer
- **Payload**: deal ID, merchant ID, signed timestamp, deal content metadata
- **Consumers**: Signed Deal Listener (self-consumption to trigger downstream workflows); other Continuum consumers tracked in central model
- **Guarantees**: at-least-once

### deal-lifecycle Detail

- **Topic**: `continuumMetroDraftMessageBus`
- **Trigger**: Deal status transitions executed by Deal Status Service through History Event Service
- **Payload**: deal ID, previous status, new status, transition timestamp
- **Consumers**: Downstream Continuum services (tracked in central architecture model)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `continuumMetroDraftMessageBus` | `signed-deal-event` | `continuumMetroDraftService_signedDealListener` | Triggers Deal Orchestration Service to execute downstream workflow for the signed deal |

### signed-deal-event Detail

- **Topic**: `continuumMetroDraftMessageBus`
- **Handler**: Signed Deal Listener receives the event and calls Deal Orchestration Service to continue the publishing workflow — syncing to DMAPI, MDS, Deal Catalog, and reserving inventory
- **Idempotency**: No evidence of explicit idempotency guards; confirm with service owner
- **Error handling**: No DLQ configuration evidenced in the architecture model; confirm retry strategy with service owner
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found for configured DLQs in the architecture model. Confirm with Metro Team (metro-dev-blr@groupon.com).
