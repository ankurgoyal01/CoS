---
service: "getaways-partner-integrator"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 3
internal_count: 3
---

# Integrations

## Overview

Getaways Partner Integrator has three external partner integrations (SiteMinder, TravelgateX, APS — all SOAP/WS-Security) and three internal Groupon platform dependencies (Getaways Inventory Service via REST, Kafka, and MBus). All external integrations are bidirectional: partners push inbound SOAP messages, and the service pushes outbound SOAP calls back to partners. Per-partner deployment variants (aps, siteminder, travelgatex) suggest the service may be deployed in partner-specific configurations.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| SiteMinder Channel Manager | SOAP / WS-Security | Receives and sends ARI updates and reservation notifications | yes | `siteminderChannelManager_6b1c` |
| TravelgateX Channel Manager | SOAP / WS-Security | Receives and sends ARI notifications | yes | `travelGateXChannelManager_43c2` |
| APS Channel Manager | SOAP / WS-Security | Receives and sends ARI notifications | yes | `apsChannelManager_8d21` |

### SiteMinder Channel Manager Detail

- **Protocol**: SOAP with WS-Security
- **Base URL / SDK**: Inbound via `/SiteConnectService` endpoint; outbound calls made by `partnerSoapClient` using Apache CXF
- **Auth**: WS-Security (username token / message signing via `cxf-rt-ws-security` 3.1.6 and `wss4j` 2.1.6)
- **Purpose**: SiteMinder is a hotel channel management platform. This service receives ARI updates and reservation bookings from SiteMinder and sends back reservation confirmations and cancellations.
- **Failure mode**: Outbound reservation SOAP calls would fail; inbound ARI updates would not be processed. MySQL logs capture request/response for replay analysis.
- **Circuit breaker**: No evidence found

### TravelgateX Channel Manager Detail

- **Protocol**: SOAP with WS-Security
- **Base URL / SDK**: Inbound via `/TravelGateXARI` endpoint; outbound calls made by `partnerSoapClient`
- **Auth**: WS-Security
- **Purpose**: TravelgateX is a travel connectivity platform. This service receives ARI notifications from TravelgateX and sends outbound ARI updates.
- **Failure mode**: ARI synchronization with TravelgateX hotels would stall; persisted logs enable recovery.
- **Circuit breaker**: No evidence found

### APS Channel Manager Detail

- **Protocol**: SOAP with WS-Security
- **Base URL / SDK**: Inbound via `/GetawaysPartnerARI` endpoint; outbound calls made by `partnerSoapClient`
- **Auth**: WS-Security
- **Purpose**: APS is a hotel channel manager. This service receives ARI notifications from APS and sends outbound ARI updates.
- **Failure mode**: ARI synchronization with APS hotels would stall; persisted logs enable recovery.
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Getaways Inventory Service | REST / HTTP | Fetches inventory hierarchy (hotels, rooms, rate plans) to resolve Groupon inventory identifiers | `getawaysInventoryService_5e8a` |
| Groupon Kafka Cluster | Kafka | Consumes partner inbound messages from Kafka topics | `grouponKafkaCluster_2c7f` |
| Groupon MBus | JMS / MBus | Consumes and publishes `InventoryWorkerMessage` events | `grouponMessageBus_7a2d` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Internal callers include Groupon operations tooling accessing the REST mapping and reservation endpoints. Channel managers (SiteMinder, TravelgateX, APS) push inbound SOAP messages to the service.

## Dependency Health

- All three external SOAP partners are considered critical path; if any partner endpoint is unreachable, inbound ARI messages for that partner cannot be processed.
- The Getaways Inventory Service is required for mapping validation; unavailability would block mapping workflows.
- Kafka and MBus failures would queue inbound partner messages; recovery depends on broker-level retention and redelivery.
- The `partnerSoapClient` logs all SOAP request/response payloads to MySQL, enabling post-failure replay analysis.
- No circuit breaker or retry framework is evidenced in the inventory; operational retry behavior to be confirmed with the Travel team.
