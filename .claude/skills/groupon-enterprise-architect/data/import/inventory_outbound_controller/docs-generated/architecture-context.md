---
service: "inventory_outbound_controller"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumInventoryOutboundController, continuumInventoryOutboundControllerDb]
---

# Architecture Context

## System Context

`continuumInventoryOutboundController` occupies the logistics orchestration layer of the Continuum platform's physical goods domain. It sits between internal commerce systems (Orders, Inventory, Deal Catalog, Pricing, Users) and external fulfillment partners (Landmark Global 3PL, Rocketman Email). The service is both an API provider (for cancellation and admin operations) and an event-driven processor (consuming and publishing to JMS topics via the message bus). Its MySQL database (`continuumInventoryOutboundControllerDb`) holds all fulfillment state, shipment records, routing configuration, and inventory unit data.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Goods Outbound Controller | `continuumInventoryOutboundController` | Backend | Java / Play Framework | 2.2 | Core logistics orchestration service handling fulfillment, shipments, cancellations, and GDPR |
| Outbound Controller Database | `continuumInventoryOutboundControllerDb` | Database | MySQL | — | Persistent store for orders, fulfillments, shipments, routing config, inventory units, and notifications |

## Components by Container

### Goods Outbound Controller (`continuumInventoryOutboundController`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `outboundApiControllers` | Handles all inbound HTTP API requests: cancellation, sales order queries, carrier info, rate estimation, fulfillment manifests, admin operations | Play Framework controllers |
| `outboundMessagingAdapters` | Subscribes to JMS topics; dispatches inbound events to orchestration; publishes outbound events | mbus-client / JMS |
| `outboundFulfillmentOrchestration` | Core business logic: eligibility checks, fulfillment routing, manifest parsing, cancellation coordination, GDPR anonymization | Java / Play |
| `outboundPersistenceAdapters` | Reads and writes fulfillment, shipment, order, and inventory data to MySQL via Hibernate | Hibernate / MySQL |
| `outboundExternalServiceClients` | HTTP clients for Inventory Service, Goods Inventory Service, Orders Service, Deal Catalog, Users, Pricing, Landmark Global, Rocketman Email, Google Sheets | Play WS / HTTP |
| `outboundSchedulingJobs` | Quartz-scheduled jobs: fulfillment import, retry/reaper, scavenger | Quartz 2.3.0 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumInventoryOutboundController` | `messageBus` | Publishes sales order updates, marketplace shipped events, GDPR completion events; consumes inventory update, logistics gateway, shipment tracker, and GDPR events | JMS / Message Bus |
| `continuumInventoryOutboundController` | `continuumInventoryService` | Queries and updates inventory quantities and eligibility | HTTP / REST |
| `continuumInventoryOutboundController` | `continuumGoodsInventoryService` | Reads goods-level inventory data | HTTP / REST |
| `continuumInventoryOutboundController` | `continuumOrdersService` | Reads order details; notifies on cancellation | HTTP / REST |
| `continuumInventoryOutboundController` | `continuumDealCatalogService` | Reads deal configuration and fulfillment deal config | HTTP / REST |
| `continuumInventoryOutboundController` | `continuumUsersService` | Reads user PII for GDPR erasure | HTTP / REST |
| `continuumInventoryOutboundController` | `continuumPricingService` | Reads pricing data for rate estimation | HTTP / REST |
| `continuumInventoryOutboundController` | `continuumInventoryOutboundControllerDb` | Persists all fulfillment state, shipments, routing config, inventory units | JDBC / MySQL |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuumInventoryOutboundController`
- Dynamic view: `dynamic-inventory-update-processing`
