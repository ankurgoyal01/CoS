---
service: "getaways-partner-integrator"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumGetawaysPartnerIntegrator, continuumGetawaysPartnerIntegratorDb]
---

# Architecture Context

## System Context

Getaways Partner Integrator is a container within the `continuumSystem` (Continuum Platform). It sits at the boundary between Groupon's internal getaways inventory domain and three external hotel channel management systems: SiteMinder, TravelgateX, and APS. Channel managers push ARI updates and reservation notifications inbound via SOAP; the service normalizes these and persists them to MySQL while coordinating with the Getaways Inventory Service via REST. Outbound SOAP calls to channel managers carry reservation confirmations and cancellations. Internal Groupon systems communicate with the service via Kafka topics and MBus JMS messages.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Getaways Partner Integrator | `continuumGetawaysPartnerIntegrator` | Service | Java, Dropwizard, Apache CXF | 3.1.6 / Java 11 | Dropwizard service integrating partner channel managers with Groupon inventory via REST/SOAP endpoints and message-driven workers |
| Getaways Partner Integrator DB | `continuumGetawaysPartnerIntegratorDb` | Database | MySQL | — | MySQL database storing partner mappings, reservation records, and SOAP request/response logs |

## Components by Container

### Getaways Partner Integrator (`continuumGetawaysPartnerIntegrator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `getawaysPartnerIntegrator_restApi` | Exposes REST endpoints for mapping management and reservation data retrieval | Dropwizard/Jersey |
| `soapApi` | Exposes SOAP endpoints for channel manager ARI updates and reservation notifications | Apache CXF |
| `getawaysPartnerIntegrator_mappingService` | Core business logic for hotel/room/rate plan mappings, validation, and workflow coordination | Java |
| `reservationService` | Processes reservation creation, updates, and cancellation requests | Java |
| `getawaysPartnerIntegrator_inventoryClient` | HTTP client for fetching inventory hierarchy from Getaways Inventory Service | Java HTTP client |
| `partnerSoapClient` | SOAP client for sending outbound reservation and cancellation calls to channel managers | Apache CXF |
| `getawaysPartnerIntegrator_kafkaConsumer` | Consumes partner inbound messages from Kafka topics | kafka-clients 0.10.2.1 |
| `mbusWorker` | Consumes `InventoryWorkerMessage` events from MBus and publishes outbound MBus messages | jtier-messagebus-client |
| `getawaysPartnerIntegrator_persistenceLayer` | DAO layer — all reads and writes to MySQL | jtier-jdbi3, jtier-daas-mysql |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGetawaysPartnerIntegrator` | `continuumGetawaysPartnerIntegratorDb` | Reads and writes partner mappings, reservations, logs | JDBC / MySQL |
| `continuumGetawaysPartnerIntegrator` | `grouponMessageBus_7a2d` | Consumes and produces InventoryWorkerMessage events | JMS / MBus |
| `continuumGetawaysPartnerIntegrator` | `grouponKafkaCluster_2c7f` | Consumes partner inbound topics | Kafka |
| `continuumGetawaysPartnerIntegrator` | `getawaysInventoryService_5e8a` | Fetches inventory hierarchy | REST / HTTP |
| `continuumGetawaysPartnerIntegrator` | `siteminderChannelManager_6b1c` | Sends reservation and cancellation SOAP requests | SOAP / WS-Security |
| `continuumGetawaysPartnerIntegrator` | `travelGateXChannelManager_43c2` | Sends ARI update SOAP requests | SOAP / WS-Security |
| `continuumGetawaysPartnerIntegrator` | `apsChannelManager_8d21` | Sends ARI update SOAP requests | SOAP / WS-Security |
| `siteminderChannelManager_6b1c` | `continuumGetawaysPartnerIntegrator` | Sends ARI and reservation notifications | SOAP inbound |
| `travelGateXChannelManager_43c2` | `continuumGetawaysPartnerIntegrator` | Sends ARI notifications | SOAP inbound |
| `apsChannelManager_8d21` | `continuumGetawaysPartnerIntegrator` | Sends ARI notifications | SOAP inbound |
| `getawaysPartnerIntegrator_restApi` | `getawaysPartnerIntegrator_mappingService` | Delegates mapping and reservation requests | Direct |
| `soapApi` | `getawaysPartnerIntegrator_mappingService` | Delegates ARI processing | Direct |
| `soapApi` | `reservationService` | Delegates reservation processing | Direct |
| `getawaysPartnerIntegrator_kafkaConsumer` | `getawaysPartnerIntegrator_mappingService` | Processes inbound partner Kafka messages | Direct |
| `mbusWorker` | `getawaysPartnerIntegrator_mappingService` | Processes inventory MBus messages | Direct |
| `getawaysPartnerIntegrator_mappingService` | `reservationService` | Coordinates reservation workflows | Direct |
| `getawaysPartnerIntegrator_mappingService` | `getawaysPartnerIntegrator_inventoryClient` | Fetches inventory hierarchy | Direct |
| `getawaysPartnerIntegrator_mappingService` | `getawaysPartnerIntegrator_persistenceLayer` | Reads/Writes mappings | Direct |
| `reservationService` | `partnerSoapClient` | Sends reservation and cancellation requests | Direct |
| `partnerSoapClient` | `getawaysPartnerIntegrator_persistenceLayer` | Persists SOAP request/response logs | Direct |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-getawaysPartnerIntegratorComponents`
