---
service: "channel-manager-integrator-synxis"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

CMI SynXis participates in two async messaging systems. It publishes validated ARI (Availability, Rates, Inventory) events to Kafka after receiving and processing SOAP push calls from SynXis CRS. It also consumes RESERVE and CANCEL request messages from MBus and publishes corresponding success/failure response messages back to MBus after coordinating the reservation workflow with SynXis.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `continuumKafkaBroker` (ARI topic) | ARI update event | Successful `pushAvailability`, `pushInventory`, or `pushRate` SOAP call | Hotel/room identifiers, availability/inventory/rate data, mapping metadata |
| `messageBus` (Inventory Service Worker topic) | Reservation/cancellation response | Completion of RESERVE or CANCEL workflow | Reservation ID, SynXis confirmation number, status (success/failure), error details |

### ARI Update Event Detail

- **Topic**: `continuumKafkaBroker` (ARI topic; exact topic name managed by platform configuration)
- **Trigger**: `soapAriIngress` receives a valid `pushAvailability`, `pushInventory`, or `pushRate` call from SynXis CRS
- **Payload**: Hotel and room identifiers, ARI data as received from SynXis, resolved internal mapping identifiers
- **Consumers**: Downstream Continuum services consuming hotel ARI data (tracked in central architecture model)
- **Guarantees**: at-least-once (Kafka producer default)

### Reservation/Cancellation Response Detail

- **Topic**: `messageBus` — Inventory Service Worker response topic
- **Trigger**: `reservationCancellationService` completes a RESERVE or CANCEL workflow (success or failure)
- **Payload**: Reservation ID, SynXis confirmation number or error, workflow status
- **Consumers**: `inventoryServiceWorker`
- **Guarantees**: at-least-once (MBus delivery)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `messageBus` (inbound request topic) | RESERVE request | `mbusInboundProcessor` | Creates reservation in SynXis; persists state to MySQL; publishes response to MBus |
| `messageBus` (inbound request topic) | CANCEL request | `mbusInboundProcessor` | Cancels reservation in SynXis; updates reservation state in MySQL; publishes response to MBus |

### RESERVE Request Detail

- **Topic**: `messageBus` inbound request topic
- **Handler**: `mbusInboundProcessor` dispatches to `reservationCancellationService`
- **Idempotency**: State is persisted to MySQL before calling SynXis; duplicate detection relies on reservation identifiers in the mapping/reservation tables
- **Error handling**: On failure, `mbusOutboundPublisher` publishes a failure response to the MBus outbound topic; no DLQ evidence found in architecture model
- **Processing order**: Unordered (MBus delivery)

### CANCEL Request Detail

- **Topic**: `messageBus` inbound request topic
- **Handler**: `mbusInboundProcessor` dispatches to `reservationCancellationService`
- **Idempotency**: Reservation state in MySQL tracks cancellation; repeated cancellation attempts use stored state to determine action
- **Error handling**: Failure response published to MBus outbound topic
- **Processing order**: Unordered (MBus delivery)

## Dead Letter Queues

> No evidence found for DLQ configuration in the architecture model. Operational procedures to be defined by service owner.
