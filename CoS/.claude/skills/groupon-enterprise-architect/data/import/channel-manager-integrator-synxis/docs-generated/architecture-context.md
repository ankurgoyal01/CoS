---
service: "channel-manager-integrator-synxis"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumChannelManagerIntegratorSynxisApp, continuumChannelManagerIntegratorSynxisDatabase]
---

# Architecture Context

## System Context

CMI SynXis sits within the Continuum platform as the dedicated integration bridge between Groupon's hotel commerce infrastructure and the SynXis Central Reservation System. It receives inbound ARI push data from SynXis (external), validates and forwards those events into Continuum's event backbone (Kafka), and mediates hotel reservation and cancellation transactions initiated by Continuum's Inventory Service Worker (via MBus) against SynXis. The service is stateful: it owns a MySQL database that persists mappings, reservation records, and SOAP request/response logs.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Channel Manager Integrator SynXis App | `continuumChannelManagerIntegratorSynxisApp` | Application | Java, Dropwizard, Apache CXF | JTier 5.14.1 | Dropwizard service that processes reservation/cancellation flows and SynXis ARI push messages |
| Channel Manager Integrator SynXis Database | `continuumChannelManagerIntegratorSynxisDatabase` | Database | MySQL | — | Stores mapping, reservation state, request/response logs, and operational metadata |

## Components by Container

### Channel Manager Integrator SynXis App (`continuumChannelManagerIntegratorSynxisApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `soapAriIngress` | Implements CMService SOAP endpoints: `pushAvailability`, `pushInventory`, `pushRate`, `ping`. Validates identifiers, fetches hierarchy, emits to Kafka. | Apache CXF / JAX-WS |
| `restMappingApi` | Exposes REST endpoints for mapping management (`GET/PUT /mapping`) and reservation retrieval (`GET /reservations`). | Dropwizard / Jersey |
| `mbusInboundProcessor` | Consumes RESERVE and CANCEL request messages from MBus and dispatches to the reservation/cancellation service. | JTier MBus Consumer |
| `reservationCancellationService` | Coordinates reservation/cancellation business logic: reads/writes state, calls SynXis, publishes responses. | Service Layer |
| `synxisClient` | Executes create, read, cancel, and ping SOAP calls to SynXis ChannelConnectService. | Apache CXF SOAP Client |
| `inventoryHierarchyClient` | Fetches hotel hierarchy from Inventory Service REST API for ARI validation and mapping. | HTTP REST Client (OkHttp) |
| `kafkaAriPublisher` | Publishes validated ARI payloads to `continuumKafkaBroker`. | Kafka Producer |
| `mbusOutboundPublisher` | Publishes reservation/cancellation response messages to Inventory Service Worker topic on MBus. | JTier MBus Writer |
| `mappingPersistence` | DAO layer for mappings, reservations, comments, and request/response logs. | JDBI3 / MySQL |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumChannelManagerIntegratorSynxisApp` | `continuumChannelManagerIntegratorSynxisDatabase` | Reads and writes mappings, reservations, and request/response logs | JDBC |
| `soapAriIngress` | `continuumKafkaBroker` | Publishes ARI events after validation | Kafka |
| `soapAriIngress` | `continuumTravelInventoryService` | Requests hotel hierarchy data for ARI validation | HTTPS/JSON |
| `kafkaAriPublisher` | `continuumKafkaBroker` | Publishes validated ARI events | Kafka |
| `mbusInboundProcessor` | `reservationCancellationService` | Dispatches RESERVE/CANCEL requests | Direct (in-process) |
| `reservationCancellationService` | `synxisClient` | Calls SynXis for create/read/cancel operations | SOAP over HTTPS |
| `synxisClient` | `synxisCrs` | Executes ChannelConnect SOAP operations | SOAP over HTTPS |
| `reservationCancellationService` | `mbusOutboundPublisher` | Publishes success/failure response | Direct (in-process) |
| `mbusOutboundPublisher` | `messageBus` | Sends reservation/cancellation response messages | MBus topic |
| `mappingPersistence` | `continuumChannelManagerIntegratorSynxisDatabase` | Persists and retrieves mappings and reservation artifacts | JDBI / MySQL |

## Architecture Diagram References

- Component: `components-channel-manager-integrator-synxis-app`
- Dynamic (ARI push flow): `dynamic-ari-push-to-kafka-flow`
- Dynamic (reservation/cancellation flow): `dynamic-reservation-cancellation-worker-flow` (disabled in federation; see [Flows](flows/index.md))
