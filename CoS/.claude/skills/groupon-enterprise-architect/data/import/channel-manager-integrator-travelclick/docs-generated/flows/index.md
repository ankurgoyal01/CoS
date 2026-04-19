---
service: "channel-manager-integrator-travelclick"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Getaways Channel Manager Integrator for TravelClick.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Hotel Reservation Processing](hotel-reservation-processing.md) | asynchronous | MBus reservation message | Consumes a Groupon hotel reservation event and delivers it to TravelClick via OTA XML |
| [Hotel Cancellation Processing](hotel-cancellation-processing.md) | asynchronous | MBus cancellation message | Consumes a Groupon hotel cancellation event and forwards it to TravelClick via OTA XML |
| [Availability Push from TravelClick](availability-push.md) | synchronous | POST from TravelClick | Receives an OTA hotel availability notification and stores/publishes the update |
| [Inventory Push from TravelClick](inventory-push.md) | synchronous | POST from TravelClick | Receives an OTA hotel inventory count notification and stores/publishes the update |
| [Rate Push from TravelClick](rate-push.md) | synchronous | POST from TravelClick | Receives an OTA hotel rate plan notification and stores/publishes the update |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The reservation and cancellation flows span three services:
1. Upstream Getaways booking service (publishes to MBus) — tracked in central architecture model
2. `continuumChannelManagerIntegratorTravelclick` (this service) — consumes, transforms, and delivers
3. TravelClick external platform (`travelclickPlatform` stub) — receives OTA XML

The ARI push flows originate at TravelClick and fan out via Kafka to downstream Getaways services — those downstream consumers are tracked in the central architecture model.
