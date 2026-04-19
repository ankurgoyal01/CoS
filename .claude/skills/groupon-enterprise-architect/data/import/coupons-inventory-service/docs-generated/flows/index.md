---
service: "coupons-inventory-service"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Coupons Inventory Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Product Creation](product-creation.md) | synchronous + asynchronous | API request (POST /products) | Creates an inventory product, persists to DB, publishes creation event for async deal-id resolution |
| [Product Query by Deal ID](product-query-by-deal-id.md) | synchronous | API request (GET /products?dealId=) | Queries products by deal-id using Redis cache with DB fallback |
| [Reservation Creation](reservation-creation.md) | synchronous | API request (POST /reservations) | Creates a reservation with validation, optional VoucherCloud code fetch, and persistence |
| [Deal ID Resolution](deal-id-resolution.md) | asynchronous | inventoryProduct.create message | Consumes product creation event, resolves deal-ids from Deal Catalog, updates DB and Redis cache |
| [Client Authentication](client-authentication.md) | synchronous | Every API request | Authenticates and authorizes client requests using client records with in-memory caching |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Mixed (synchronous + asynchronous) | 1 |

## Cross-Service Flows

- **Product creation with deal-id resolution**: Spans Coupons Inventory Service (product creation and event publishing), IS Core Message Bus (event delivery), and Deal Catalog Service (deal-id lookup). See [Product Creation](product-creation.md) and [Deal ID Resolution](deal-id-resolution.md).
- **Reservation with redemption codes**: Spans Coupons Inventory Service (reservation creation) and VoucherCloud (redemption code fetch). See [Reservation Creation](reservation-creation.md).

> Dynamic views are not yet defined in the architecture DSL for this service. These flow documents are derived from component relationships in the architecture model.
