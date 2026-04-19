---
service: "channel-manager-integrator-synxis"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for Channel Manager Integrator SynXis.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [ARI Push to Kafka Flow](ari-push-to-kafka.md) | event-driven | SynXis CRS calls `pushAvailability`, `pushInventory`, or `pushRate` on `/soap/CMService` | SynXis pushes ARI updates; service validates, enriches, and publishes events to Kafka |
| [Reservation and Cancellation Worker Flow](reservation-cancellation-worker.md) | asynchronous | Inventory Service Worker publishes RESERVE or CANCEL to MBus | Consumes reservation/cancellation requests from MBus, coordinates with SynXis CRS via SOAP, persists state, and publishes response to MBus |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

Both flows span multiple services in the Continuum architecture:

- **ARI Push to Kafka**: Spans `synxisCrs` (external), `continuumChannelManagerIntegratorSynxisApp`, `continuumTravelInventoryService`, and `continuumKafkaBroker`. Architecture dynamic view: `dynamic-ari-push-to-kafka-flow`.

- **Reservation and Cancellation Worker**: Spans `inventoryServiceWorker`, `messageBus`, `continuumChannelManagerIntegratorSynxisApp`, and `synxisCrs` (external). The architecture dynamic view (`dynamic-reservation-cancellation-worker-flow`) is disabled in the federation model because `inventoryServiceWorker` is a stub-only element not present in the central workspace; the flow is fully documented from component relations and the commented DSL.
