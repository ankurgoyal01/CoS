---
service: "channel-manager-integrator-derbysoft"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumChannelManagerIntegratorDerbysoftApp", "continuumChannelManagerIntegratorDerbysoftDb"]
---

# Architecture Context

## System Context

The Channel Manager Integrator Derbysoft service sits within the **Continuum** platform and belongs to the Getaways domain. It acts as the integration boundary between Groupon's internal booking infrastructure and the external Derbysoft channel manager. Internally, it interacts with the MBus broker (`continuumMbusBroker`) to receive inbound booking/cancellation instructions from the Inventory Service Worker and to respond with booking outcomes. It also publishes ARI events to the Kafka broker (`continuumKafkaBroker`). Externally, it communicates with the Derbysoft Channel Manager API over HTTPS and with the Getaways Inventory API for hotel hierarchy data used in mapping workflows.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Channel Manager Integrator Derbysoft App | `continuumChannelManagerIntegratorDerbysoftApp` | Service | Java, Dropwizard | Java 11 | Dropwizard service handling Derbysoft channel-manager reservations, cancellations, ARI, and mapping workflows |
| Channel Manager Integrator Derbysoft DB | `continuumChannelManagerIntegratorDerbysoftDb` | Database | PostgreSQL | — | Persists reservation, cancellation, ARI request/response, and external mapping data |

## Components by Container

### Channel Manager Integrator Derbysoft App (`continuumChannelManagerIntegratorDerbysoftApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Derbysoft API Controllers | Exposes HTTP endpoints for ARI push, hotel sync, resource mapping, and reservation data APIs | JAX-RS |
| Reservation Workflow Service | Coordinates prebook, book, and reservation detail request processing using a state machine (RESERVATION_INIT, PRE_BOOK_SUCCEED, PRE_BOOK_FAILED, BOOK_SUCCEED, BOOK_FAILED) | Service |
| Cancellation Workflow Service | Coordinates reservation cancellation request processing against the Derbysoft cancel endpoint | Service |
| ARI Push Processor | Validates and processes Daily ARI push payloads from Derbysoft partners | Processor |
| Resource Mapping Service | Builds and updates internal/external room-type and rate-plan mappings using hotel hierarchy from the Inventory API | Service |
| External Integration Clients | Calls Derbysoft reservation/cancellation endpoints and the Getaways Inventory hierarchy endpoint via Retrofit2 HTTP clients | Retrofit Clients |
| Messaging Adapter | Consumes `RequestMessageContainer` booking notifications from MBus and emits `ResponseMessageContainer` booking response events; publishes `ARIMessage` payloads to Kafka | MBus/Kafka |
| Persistence Adapter | DAO layer for reservation, cancellation, ARI request/response, hotel, room-type, rate-plan, and external hierarchy mapping persistence | JDBI/DAO |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumChannelManagerIntegratorDerbysoftApp` | `continuumChannelManagerIntegratorDerbysoftDb` | Reads and writes reservation, cancellation, ARI, and mapping data | JDBI/PostgreSQL |
| `continuumChannelManagerIntegratorDerbysoftApp` | `continuumMbusBroker` | Consumes booking notifications and publishes booking responses | STOMP/JMS |
| `continuumChannelManagerIntegratorDerbysoftApp` | `continuumKafkaBroker` | Publishes partner inbound ARI payload events | Kafka |
| `derbysoftApi` (component) | `reservationWorkflowChaManInt` (component) | Submits reservation detail/prebook/book requests | in-process |
| `derbysoftApi` (component) | `cancellationWorkflow` (component) | Submits cancellation requests | in-process |
| `derbysoftApi` (component) | `ariPushProcessor` (component) | Submits Daily ARI push requests | in-process |
| `derbysoftApi` (component) | `channelManagerIntegratorDerbysoft_mappingService` (component) | Submits resource mapping updates | in-process |
| `reservationWorkflowChaManInt` (component) | `outboundClients` (component) | Calls Derbysoft reservation endpoints | HTTPS/JSON |
| `reservationWorkflowChaManInt` (component) | `persistenceAdapterChaManInt` (component) | Stores request and response records | JDBI |
| `reservationWorkflowChaManInt` (component) | `messagingAdapter_ChaManIntD` (component) | Publishes booking outcome events | in-process |
| `cancellationWorkflow` (component) | `outboundClients` (component) | Calls Derbysoft cancellation endpoint | HTTPS/JSON |
| `ariPushProcessor` (component) | `channelManagerIntegratorDerbysoft_mappingService` (component) | Resolves hotel, room-type, and rate-plan mappings | in-process |
| `ariPushProcessor` (component) | `persistenceAdapterChaManInt` (component) | Stores ARI request and response records | JDBI |
| `ariPushProcessor` (component) | `messagingAdapter_ChaManIntD` (component) | Publishes partner ARI payload to Kafka topic | in-process |
| `channelManagerIntegratorDerbysoft_mappingService` (component) | `outboundClients` (component) | Fetches hotel hierarchy from Inventory service | HTTP/JSON |
| `messagingAdapter_ChaManIntD` (component) | `reservationWorkflowChaManInt` (component) | Dispatches MBus booking messages for processing | in-process |

## Architecture Diagram References

- Container: `containers-continuumChannelManagerIntegratorDerbysoftApp`
- Component: `components-continuumChannelManagerIntegratorDerbysoftApp`
- Dynamic view: `dynamic-ReservationProcessingFlow`
