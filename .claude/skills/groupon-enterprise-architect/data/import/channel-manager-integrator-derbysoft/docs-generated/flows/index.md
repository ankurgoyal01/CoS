---
service: "channel-manager-integrator-derbysoft"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Channel Manager Integrator Derbysoft service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Reservation Processing](reservation-processing.md) | asynchronous | MBus `RESERVE` message from ISW | Receives a reserve request, runs prebook → book state machine against Derbysoft, persists state, responds via MBus |
| [Cancellation Processing](cancellation-processing.md) | asynchronous | MBus `CANCEL` message from ISW | Receives a cancellation request, submits cancel to Derbysoft, persists result, responds via MBus |
| [Daily ARI Push](daily-ari-push.md) | synchronous | HTTP POST from Derbysoft partner | Validates and processes inbound ARI payload, persists request/response, publishes `ARIMessage` to Kafka |
| [Resource Mapping Update](resource-mapping-update.md) | synchronous | HTTP PUT from internal tooling | Fetches hotel hierarchy from Inventory API, builds or updates external-to-internal hotel/room-type/rate-plan mappings in PostgreSQL |
| [Dead Letter Queue Processing](dlq-processing.md) | asynchronous | MBus DLQ message (unprocessable booking) | Marks failed reservations in the database and sends a failure response back to ISW via MBus |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The **Reservation Processing** and **Cancellation Processing** flows span multiple services: ISW (upstream MBus producer) → Channel Manager Integrator Derbysoft → Derbysoft Channel Manager API (external) → MBus (response back to ISW). The dynamic view `dynamic-ReservationProcessingFlow` in the Structurizr model documents the reservation path. See [Architecture Context](../architecture-context.md) for container-level relationship details.
