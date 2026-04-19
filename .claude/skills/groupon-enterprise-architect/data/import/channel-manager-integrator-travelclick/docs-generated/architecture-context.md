---
service: "channel-manager-integrator-travelclick"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumChannelManagerIntegratorTravelclick"
  containers:
    - continuumChannelManagerIntegratorTravelclick
    - continuumChannelManagerIntegratorTravelclickMySql
---

# Architecture Context

## System Context

The channel-manager-integrator-travelclick sits within the Continuum Getaways platform as a bidirectional integration worker between Groupon's internal reservation system and the TravelClick external channel manager. It receives asynchronous reservation and cancellation events from the internal MBus message bus, translates them to OTA XML, and delivers them to TravelClick. In the other direction, TravelClick pushes availability, inventory, and rate updates to this service's REST endpoints, which then fanout those updates to Kafka and MySQL for downstream consumption. The service also calls the Getaways Inventory service to resolve hotel hierarchy and product metadata needed to build TravelClick requests.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Channel Manager Integrator TravelClick App | `continuumChannelManagerIntegratorTravelclick` | Service / Worker | Java 11, Dropwizard, JDBI | Dropwizard service that consumes channel-manager messages, invokes TravelClick APIs, publishes ARI events, and exposes REST endpoints |
| Channel Manager Integrator TravelClick MySQL | `continuumChannelManagerIntegratorTravelclickMySql` | Database | MySQL | Persistence for reservation, cancellation, request, and response records |

## Components by Container

### Channel Manager Integrator TravelClick App (`continuumChannelManagerIntegratorTravelclick`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `cmiTc_apiControllers` | REST controllers for ARI push (availability, inventory, rate), hotel products, and reservation endpoints | JAX-RS, Dropwizard |
| `cmiTc_mbusConsumer` | Consumes reservation and cancellation messages from MBus topics and DLQ | JTier MessageBus |
| `cmiTc_travelclickClient` | Builds and sends OTA XML requests to TravelClick; logs requests and responses | OkHttp, JAXB |
| `cmiTc_inventoryClient` | Calls the Getaways Inventory API for hotel hierarchy and product info | HTTP Client (JTier OkHttp) |
| `cmiTc_persistence` | JDBI DAOs for reservation and ARI request/response persistence in MySQL | JDBI, MySQL |
| `cmiTc_kafkaProducer` | Publishes ARI-related messages to Kafka topics | Kafka Client 0.10.2.1 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumChannelManagerIntegratorTravelclick` | `continuumChannelManagerIntegratorTravelclickMySql` | Reads and writes service data | JDBC/JDBI |
| `messageBus` | `continuumChannelManagerIntegratorTravelclick` | Delivers reservation and cancellation messages | MBus |
| `continuumChannelManagerIntegratorTravelclick` | `messageBus` | Publishes channel manager response messages | MBus |
| `continuumChannelManagerIntegratorTravelclick` | `travelclickPlatform` | Sends OTA reservation/cancellation requests | HTTPS / OTA XML |
| `continuumChannelManagerIntegratorTravelclick` | `getawaysInventoryService` | Fetches inventory hierarchy and hotel product data | HTTP/REST |
| `continuumChannelManagerIntegratorTravelclick` | `kafkaCluster` | Publishes ARI events | Kafka |
| `cmiTc_apiControllers` | `cmiTc_inventoryClient` | Fetches hotel hierarchy and product data | Internal |
| `cmiTc_apiControllers` | `cmiTc_kafkaProducer` | Publishes ARI payloads | Internal |
| `cmiTc_apiControllers` | `cmiTc_persistence` | Stores and retrieves reservation data | Internal |
| `cmiTc_mbusConsumer` | `cmiTc_travelclickClient` | Processes reservation/cancellation workflows through TravelClick | Internal |
| `cmiTc_mbusConsumer` | `cmiTc_persistence` | Reads/writes reservation and request/response records | Internal |
| `cmiTc_travelclickClient` | `cmiTc_persistence` | Logs TravelClick requests and responses | Internal |

## Architecture Diagram References

- Container: `containers-continuumChannelManagerIntegratorTravelclick`
- Component: `components-continuum-channel-manager-integrator-travelclick`

> System context and dynamic views are defined in the central architecture model at `structurizr/import/channel-manager-integrator-travelclick/architecture/`.
