---
service: "getaways-partner-integrator"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Getaways Partner Integrator.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Partner Availability Inbound](partner-availability-inbound.md) | synchronous | Inbound SOAP ARI message from channel manager | Channel manager sends ARI (Availability/Rates/Inventory) update; service validates, persists mapping, and coordinates downstream inventory update |
| [Partner Reservation Inbound](partner-reservation-inbound.md) | synchronous | Inbound SOAP reservation notification from channel manager | Channel manager sends reservation booking; service processes, persists, and confirms via outbound SOAP call |
| [Inventory Mapping REST API](inventory-mapping-rest-api.md) | synchronous | REST API call (GET/PUT) from internal consumer | Internal caller retrieves or updates hotel/room/rate plan mapping records via REST; service reads/writes MySQL |
| [Kafka Partner Inbound Stream](kafka-partner-inbound-stream.md) | event-driven | Kafka message on partner inbound topic | Partner message arrives on Kafka; consumer delegates to mapping service for ARI processing and MySQL persistence |
| [MBus Inventory Worker Outbound](mbus-inventory-worker-outbound.md) | event-driven | InventoryWorkerMessage consumed from MBus | Service receives inventory worker task from MBus; executes mapping workflow; publishes outbound InventoryWorkerMessage to trigger downstream processing |
| [Health Check and Monitoring](health-check-and-monitoring.md) | synchronous | Kubernetes liveness/readiness probe or admin request | Kubernetes or operator polls Dropwizard health check endpoints to verify service and dependency health |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |
| Monitoring / Infrastructure | 1 |

## Cross-Service Flows

- **Partner Availability Inbound** and **Partner Reservation Inbound** span the boundary between external channel managers (`siteminderChannelManager_6b1c`, `travelGateXChannelManager_43c2`, `apsChannelManager_8d21`) and the internal Continuum platform (`continuumGetawaysPartnerIntegrator`, `getawaysInventoryService_5e8a`).
- **MBus Inventory Worker Outbound** connects `continuumGetawaysPartnerIntegrator` to downstream inventory workers via `grouponMessageBus_7a2d`.
- **Kafka Partner Inbound Stream** bridges `grouponKafkaCluster_2c7f` into `continuumGetawaysPartnerIntegrator` mapping workflows.
- Central architecture dynamic views: `dynamic-getawaysPartnerIntegrator` (no dynamic views defined in current DSL; see `components-getawaysPartnerIntegratorComponents` for component diagram).
