---
service: "deal_centre_api"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Deal Centre API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Deal Creation](merchant-deal-creation.md) | synchronous | Merchant submits a new deal via Deal Centre UI | Merchant creates a deal and its options; API orchestrates persistence and DMAPI delegation |
| [Buyer Deal Purchase](buyer-deal-purchase.md) | synchronous | Buyer selects and purchases a deal option | Buyer initiates purchase; API validates inventory, processes the workflow, and confirms the order |
| [Inventory Event Processing](inventory-event-processing.md) | event-driven | Inventory event arrives on Message Bus | API consumes an inbound inventory event and updates deal centre inventory state |
| [Deal Catalog Sync](deal-catalog-sync.md) | event-driven | Deal catalog event arrives on Message Bus | API consumes a catalog event and synchronizes product catalog state in PostgreSQL |
| [Product Catalog Management](product-catalog-management.md) | synchronous | Admin submits a catalog product create or update | Admin creates or updates a product catalog entry; API persists and publishes a catalog updated event |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Merchant Deal Creation** involves `continuumDealManagementApi` for deal and option mutation. See the central architecture model (`continuumSystem`) for the cross-service container view.
- **Inventory Event Processing** and **Deal Catalog Sync** cross `messageBus`, `continuumDealCentreApi`, and `continuumDealCentrePostgres`. These flows are candidates for a dynamic view in `views/dynamics.dsl`.
- **Product Catalog Management** publishes to `messageBus` which is consumed by `continuumDealCatalogService` and other downstream Continuum services.
