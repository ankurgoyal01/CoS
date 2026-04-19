---
service: "deals-cluster-api-jtier"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus, jms]
---

# Events

## Overview

The Deals Cluster API uses Groupon's JMS-based message bus (mbus) for the marketing tagging workflow. When a tagging use case is executed, the Use Case Execute Service publishes tagging or untagging messages to dedicated JMS queues. Two worker components (`taggingWorker` and `untaggingWorker`) run within the same application and consume these messages, calling the Marketing Deal Service to apply or remove tags on deals.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `messageBusTaggingQueue` | Tagging Request | Use case execution triggers tag application | Deal identifiers, tag name, use case context |
| `messageBusUntaggingQueue` | Untagging Request | Use case execution triggers tag removal | Deal identifiers, tag name, use case context |

### Tagging Request Detail

- **Topic**: `messageBusTaggingQueue`
- **Trigger**: Use Case Execute Service executes a tagging use case (scheduled or manual)
- **Payload**: Deal identifiers and tag metadata (specific field schema not exposed in DSL; inferred from use case context)
- **Consumers**: `taggingWorker` (within this service), which calls `continuumMarketingDealService` to apply the tag
- **Guarantees**: at-least-once (JMS default)

### Untagging Request Detail

- **Topic**: `messageBusUntaggingQueue`
- **Trigger**: Use Case Execute Service executes an untagging use case (scheduled or manual)
- **Payload**: Deal identifiers and tag metadata
- **Consumers**: `untaggingWorker` (within this service), which calls `continuumMarketingDealService` to remove the tag
- **Guarantees**: at-least-once (JMS default)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `messageBusTaggingQueue` | Tagging Request | `taggingWorker` | Calls `continuumMarketingDealService` to apply deal tag; persists tagging audit entry |
| `messageBusUntaggingQueue` | Untagging Request | `untaggingWorker` | Calls `continuumMarketingDealService` to remove deal tag; persists tagging audit entry |

### Tagging Request (Consumed) Detail

- **Topic**: `messageBusTaggingQueue`
- **Handler**: Tagging Worker — calls DM API Client which calls `continuumMarketingDealService`
- **Idempotency**: Not explicitly documented; depends on Marketing Deal Service behavior
- **Error handling**: Standard JMS retry semantics via `jtier-messagebus-dropwizard`
- **Processing order**: unordered

### Untagging Request (Consumed) Detail

- **Topic**: `messageBusUntaggingQueue`
- **Handler**: Untagging Worker — calls DM API Client which calls `continuumMarketingDealService`
- **Idempotency**: Not explicitly documented; depends on Marketing Deal Service behavior
- **Error handling**: Standard JMS retry semantics via `jtier-messagebus-dropwizard`
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase of explicit DLQ configuration. Standard JMS/mbus DLQ behavior managed by the message bus infrastructure.
