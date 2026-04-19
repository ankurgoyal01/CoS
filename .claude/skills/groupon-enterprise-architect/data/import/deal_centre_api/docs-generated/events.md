---
service: "deal_centre_api"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Deal Centre API participates in Groupon's internal Message Bus (`messageBus`) for async event-driven processing. The service both publishes events (outbound inventory and deal catalog changes) and consumes events (inbound inventory and catalog updates). The `dca_messageBusIntegration` component handles all MBus producers and consumers, delegating processing triggers to `dca_domainServices`.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `messageBus` (inventory topic) | Inventory Updated | Inventory quantity changes via merchant or buyer workflow | deal ID, option ID, inventory delta, timestamp |
| `messageBus` (deal catalog topic) | Deal Catalog Updated | Deal or product catalog entry created, updated, or deleted | deal ID, product ID, catalog version, change type, timestamp |

### Inventory Updated Detail

- **Topic**: `messageBus` — inventory channel
- **Trigger**: Merchant or buyer action that modifies deal inventory (e.g., option purchase, stock adjustment)
- **Payload**: deal ID, option ID, inventory delta, timestamp
- **Consumers**: Downstream Continuum services that track inventory availability
- **Guarantees**: at-least-once (MBus standard)

### Deal Catalog Updated Detail

- **Topic**: `messageBus` — deal catalog channel
- **Trigger**: Creation, update, or removal of a deal or product catalog entry
- **Payload**: deal ID, product ID, catalog version, change type, timestamp
- **Consumers**: `continuumDealCatalogService` and other Continuum catalog consumers
- **Guarantees**: at-least-once (MBus standard)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `messageBus` (inventory channel) | Inventory Event | `dca_messageBusIntegration` -> `dca_domainServices` | Updates inventory state in `continuumDealCentrePostgres` |
| `messageBus` (deal catalog channel) | Catalog Event | `dca_messageBusIntegration` -> `dca_domainServices` | Synchronizes catalog state in `continuumDealCentrePostgres` |

### Inventory Event Detail (Consumed)

- **Topic**: `messageBus` — inventory channel
- **Handler**: `dca_messageBusIntegration` receives the event and invokes `dca_domainServices` to process inventory state changes
- **Idempotency**: No explicit evidence; standard MBus retry semantics apply
- **Error handling**: Standard MBus retry; dead letter behavior managed by MBus infrastructure
- **Processing order**: unordered

### Catalog Event Detail (Consumed)

- **Topic**: `messageBus` — deal catalog channel
- **Handler**: `dca_messageBusIntegration` receives the event and invokes `dca_domainServices` to apply catalog updates
- **Idempotency**: No explicit evidence; standard MBus retry semantics apply
- **Error handling**: Standard MBus retry; dead letter behavior managed by MBus infrastructure
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found for explicitly configured dead letter queues in this service's architecture model. DLQ behavior is managed by the central MBus infrastructure.
