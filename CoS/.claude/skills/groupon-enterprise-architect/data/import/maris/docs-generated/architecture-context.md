---
service: "maris"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTravelInventoryService", "marisMySql"]
---

# Architecture Context

## System Context

MARIS is a container within the `continuumSystem` (Continuum Platform) software system. It serves as the Getaways vertical's hotel inventory and reservation engine, sitting between Groupon's commerce and search layers and the Expedia partner APIs. It is referenced in the central architecture model as `continuumTravelInventoryService`.

Internal Groupon services (Travel Search, Deal Catalog, Orders) interact with MARIS via HTTP/JSON REST APIs. MARIS in turn communicates with Expedia EAN and Rapid APIs over HTTPS for availability queries and booking operations. Async coordination with the Orders Service occurs via the `messageBus` (MBus) using JMS topics.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MARIS Service | `continuumTravelInventoryService` | Backend service | Java 11, Dropwizard / JTier 5.14.0 | 5.14.0 | Hotel inventory and reservation service exposing REST APIs and consuming/publishing MBus events |
| MARIS MySQL | `marisMySql` | Database | MySQL | — | Primary transactional datastore for reservations, status logs, Expedia responses, and inventory unit state |

## Components by Container

### MARIS Service (`continuumTravelInventoryService`)

> Note: Components are defined in the MARIS repository scope but cannot be directly attached to the shared `continuumTravelInventoryService` container in the federated workspace. The following components describe internal structure as documented in the local architecture model.

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`marisApiResources`) | Dropwizard resources and Spaceman iCore facades that expose hotel room, availability, reservation, and unit APIs | JAX-RS, Spaceman iCore |
| Core Orchestration Services (`marisCoreOrchestration`) | Domain services and checkout flow orchestration for reservation creation, cancellation, pricing, and unit lifecycle handling | Java Services |
| Downstream Integration Clients (`marisDownstreamClients`) | Typed clients for Orders, Deal Catalog, Expedia Rapid, Content, and Travel Search integrations | Retrofit / HTTP Clients |
| Persistence Layer (`marisPersistence`) | Repositories and JDBI DAOs for reservations, status logs, unit state, and stored Expedia responses | JDBI, MySQL |
| Message Bus Handlers (`marisEventHandlers`) | Message bus consumers/publishers for order status changes, inventory updates, and GDPR erasure flows | JMS Handlers |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumTravelInventoryService` | `marisMySql` | Stores and reads reservations, units, status logs, and Expedia payloads | JDBC |
| `continuumTravelInventoryService` | `continuumOrdersService` | Authorizes, captures, and reverses inventory unit payments | HTTP/JSON |
| `continuumTravelInventoryService` | `continuumDealCatalogService` | Resolves legacy product identifiers | HTTP/JSON |
| `continuumTravelInventoryService` | `messageBus` | Publishes unit updates and consumes order/GDPR topics | JMS Topics/Queues |
| `continuumTravelInventoryService` | Expedia Rapid API | Retrieves availability/content and books/cancels itineraries | HTTPS API |
| `continuumTravelInventoryService` | Content Service | Fetches hotel content metadata | HTTP/JSON |
| `continuumTravelInventoryService` | Travel Search Service | Fetches travel search hotel details | HTTP/JSON |

## Architecture Diagram References

- Component: `components-continuum-travel-inventory-service-maris`
- System context: Defined in central `continuumSystem` workspace
- Container: Defined in central `continuumSystem` workspace
