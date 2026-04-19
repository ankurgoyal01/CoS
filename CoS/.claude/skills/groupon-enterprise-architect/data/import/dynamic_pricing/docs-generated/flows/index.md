---
service: "dynamic_pricing"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the Pricing Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Create Retail Price](create-retail-price.md) | synchronous | PUT /pricing_service/v2.0/product/{id}/retail_price | Validates and persists a retail price update, invalidates Redis cache, and publishes price change events |
| [Bulk Program Price Creation](bulk-program-price-creation.md) | synchronous | POST /pricing_service/v2.0/program_price | Validates and bulk-creates program prices using VIS and Deal Catalog data, then triggers the price update pipeline |
| [Inventory Event Processing](inventory-event-processing.md) | event-driven | InventoryUnits.Updated.Vis / InventoryProducts.UpdatedSnapshot.Vis MBus events | Consumes VIS inventory events and synchronizes pricing state and parity data |
| [Price Rule Schedule Job](price-rule-schedule-job.md) | scheduled | Quartz scheduler / scheduled update worker | Applies scheduled price changes and emits price events on configured cadences |
| [Get Current Price Cache Lookup](get-current-price-cache-lookup.md) | synchronous | GET /pricing_service/v2.0/product/{id}/current_price | Serves current price summary from Redis cache; falls back to DB on miss |
| [Price History Query](price-history-query.md) | synchronous | GET /pricing_service/v2.0/history/quote_id/{id} | Retrieves historical price records by quote ID for audit and reporting |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **Create Retail Price** and **Bulk Program Price Creation** flows cross service boundaries to `continuumVoucherInventoryService` and `continuumDealCatalogService` for validation, then emit events to `continuumMbusBroker` consumed by downstream Continuum services. See architecture dynamic view `dynamic-pricing-update-continuumPricingService_priceUpdateWorkflow`.
- The **Inventory Event Processing** flow is driven by events originating in `continuumVoucherInventoryService` and delivered through `continuumMbusBroker`.
- All inbound REST flows pass through `continuumDynamicPricingNginx` as the routing proxy. See architecture dynamic view `dynamic-pricing-nginx-request-routing`.
