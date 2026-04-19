---
service: "channel-manager-integrator-synxis"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 3
---

# Integrations

## Overview

CMI SynXis has one external dependency (SynXis CRS) and three internal Continuum platform dependencies (Kafka, MBus, and Inventory Service). The external SOAP integration is bidirectional: SynXis pushes ARI data inbound, and this service calls SynXis outbound for reservation operations. All internal dependencies are platform infrastructure or peer services within the Continuum ecosystem.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| SynXis CRS | SOAP over HTTPS | Receives ARI push calls inbound; called outbound for reservation/cancellation | yes | `synxisCrs` |

### SynXis CRS Detail

- **Protocol**: SOAP over HTTPS (both inbound and outbound)
- **Base URL / SDK**: Apache CXF 3.1.6 client targeting SynXis ChannelConnectService endpoint (exact URL managed by service configuration)
- **Auth**: > No evidence found in architecture model; refer to service configuration for SOAP security settings
- **Purpose**:
  - **Inbound**: SynXis CRS calls `/soap/CMService` to push `pushAvailability`, `pushInventory`, `pushRate`, and `ping` operations
  - **Outbound**: `synxisClient` calls SynXis ChannelConnectService to create reservations, read reservation details, and cancel reservations
- **Failure mode**: Inbound ARI pushes cannot be published to Kafka if SynXis is unreachable (no calls are made outbound for ARI ingress). Outbound reservation calls failing will result in a failure response published to MBus; reservations will not be confirmed in SynXis.
- **Circuit breaker**: > No evidence found in architecture model

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Continuum Kafka Broker | Kafka | Receives validated ARI events published by this service | `continuumKafkaBroker` |
| MBus | MBus topic/queue | Delivers RESERVE/CANCEL requests inbound; receives reservation/cancellation responses outbound | `messageBus` |
| Continuum Travel Inventory Service | HTTPS/JSON | Provides hotel hierarchy data for ARI validation and mapping resolution | `continuumTravelInventoryService` |

### Continuum Kafka Broker Detail

- **Protocol**: Kafka (client version 0.10.2.1)
- **Purpose**: Receives ARI events after `soapAriIngress` validates an inbound push from SynXis
- **Failure mode**: ARI events cannot be published downstream if Kafka is unavailable; inbound SOAP response to SynXis may indicate failure

### MBus Detail

- **Protocol**: JTier MBus topic/queue (`jtier-messagebus-client`)
- **Purpose**: Inbound — delivers RESERVE and CANCEL request messages to `mbusInboundProcessor`. Outbound — `mbusOutboundPublisher` sends reservation/cancellation response messages to the Inventory Service Worker topic.
- **Failure mode**: RESERVE/CANCEL requests cannot be processed if MBus is unavailable; responses cannot be delivered to the Inventory Service Worker

### Continuum Travel Inventory Service Detail

- **Protocol**: HTTPS/JSON (OkHttp REST client)
- **Purpose**: `inventoryHierarchyClient` fetches hotel hierarchy data required to validate and enrich inbound ARI payloads from SynXis
- **Failure mode**: ARI validation cannot be completed if Inventory Service is unavailable; inbound SOAP push will fail validation and the event will not be published to Kafka

## Consumed By

> Upstream consumers are tracked in the central architecture model. The known upstream producer of RESERVE/CANCEL requests is `inventoryServiceWorker` via MBus. SynXis CRS is the upstream source of SOAP ARI push calls.

## Dependency Health

> No circuit breaker or retry configuration is evidenced in the architecture model. Operational procedures to be defined by service owner.
