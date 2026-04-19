---
service: "command-center"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Command Center participates in asynchronous messaging via the internal `messageBus` (MBus). The web container (`continuumCommandCenterWeb`) both publishes and consumes workflow events on the message bus. The worker container (`continuumCommandCenterWorker`) receives events delivered by the message bus for erasure and support workflows. Specific topic names and event schemas are not enumerated in the architecture DSL.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `messageBus` (MBus) | Workflow events | Completion or state change of an operational tool workflow | Tool type, job ID, outcome status |

### Workflow Event Detail

- **Topic**: `messageBus` (MBus — internal message bus)
- **Trigger**: Completion or significant state transition of an internal operational tool workflow initiated via `continuumCommandCenterWeb`
- **Payload**: Tool type, job identifier, outcome status (inferred from relations.dsl — specific schema not defined in architecture inventory)
- **Consumers**: Other Continuum platform services subscribed to workflow events (not enumerated in this inventory)
- **Guarantees**: > No evidence found in the architecture inventory.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `messageBus` (MBus) | Erasure and support workflow events | `continuumCommandCenterWorker` | Triggers data erasure or support processing jobs |

### Erasure / Support Workflow Event Detail

- **Topic**: `messageBus` (MBus — internal message bus)
- **Handler**: `continuumCommandCenterWorker` — the worker container receives delivered events and dispatches to `cmdCenter_workerJobs` for processing
- **Idempotency**: > No evidence found in the architecture inventory.
- **Error handling**: > No evidence found in the architecture inventory. Standard Delayed Job retry behavior is expected.
- **Processing order**: Unordered (delayed_job queue-based processing)

## Dead Letter Queues

> No evidence found. Dead letter queue configuration is not defined in the architecture inventory.
