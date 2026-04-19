---
service: "deal-book-service"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Deal Book Service participates in asynchronous messaging as a consumer only. It subscribes to taxonomy content update events via the message bus (JMS topic) using the `messagebus 0.2.15` library. The `dealBookMessageWorker` container processes these events to keep fine print clause-to-category mappings synchronized with taxonomy changes. The service does not publish any async events.

## Published Events

> Not applicable — this service does not publish async events.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.taxonomyV2.content.update` | Taxonomy content update | `dealBookMessageWorker` | Updates fine print clause category mappings in MySQL |

### Taxonomy Content Update Detail

- **Topic**: `jms.topic.taxonomyV2.content.update`
- **Handler**: `dealBookMessageWorker` — processes incoming taxonomy change events and reconciles affected clause-category mappings in the `continuumDealBookMysql` database
- **Idempotency**: Not discoverable from inventory — operational procedures to be defined by service owner
- **Error handling**: Not discoverable from inventory — operational procedures to be defined by service owner
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase.
