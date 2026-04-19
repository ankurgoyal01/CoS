---
service: "mds"
title: "Inventory Status Aggregation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "inventory-status-aggregation"
flow_type: synchronous
trigger: "Deal API query requesting inventory-enriched deal data"
participants:
  - "continuumMarketingDealService"
  - "continuumMarketingDealDb"
  - "continuumInventoryService"
  - "continuumVoucherInventoryApi"
  - "continuumGoodsInventoryService"
  - "continuumThirdPartyInventoryService"
  - "continuumTravelInventoryService"
  - "continuumGLiveInventoryService"
architecture_ref: "dynamic-mds-deal-query-flow"
---

# Inventory Status Aggregation

## Summary

The inventory status aggregation flow handles synchronous deal API queries that require real-time inventory enrichment. When a client queries deals via the JTier API, the Deal Query and Filter Engine loads matching deals from PostgreSQL, then delegates to the Inventory Aggregation Service to fan out requests to domain-specific inventory services. The aggregated inventory status (available, sold out, limited) is merged into the deal response payload before returning to the caller. This flow is documented as the `dynamic-mds-deal-query-flow` dynamic view in the architecture model.

## Trigger

- **Type**: api-call
- **Source**: Internal consumers query deals via JTier API endpoints (e.g., GET `/deals`, GET `/deals/{id}`)
- **Frequency**: Per request; high frequency during peak hours

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal API Resources | Receives HTTP request, validates query params | `dealApiResources` |
| Deal Query and Filter Engine | Builds query, loads deals, orchestrates enrichment | `dealQueryAndFilterEngine` |
| Deal Persistence Gateway | Reads deal data from PostgreSQL | `dealPersistenceGateway` |
| Inventory Aggregation Service | Fans out to inventory services, merges results | `inventoryAggregationService` |
| External Service Adapters | HTTP clients for inventory service calls | `externalAdapters` |
| Marketing Deal Service Database | Source of deal data | `continuumMarketingDealDb` |
| Federated Inventory Service | Federated inventory data source | `continuumInventoryService` |
| Voucher Inventory API | Voucher inventory status | `continuumVoucherInventoryApi` |
| Goods Inventory Service | Goods inventory status | `continuumGoodsInventoryService` |
| Third-Party Inventory Service | Third-party inventory status | `continuumThirdPartyInventoryService` |
| Travel Inventory Service | Travel inventory status | `continuumTravelInventoryService` |
| GLive Inventory Service | GLive inventory status | `continuumGLiveInventoryService` |

## Steps

1. **Receive API request**: Deal API Resources accepts the HTTP request and validates query parameters (filters, pagination, inventory enrichment flags).
   - From: API Client
   - To: `dealApiResources`
   - Protocol: REST/HTTP (JAX-RS)

2. **Delegate to query engine**: Deal API Resources delegates the validated request to the Deal Query and Filter Engine.
   - From: `dealApiResources`
   - To: `dealQueryAndFilterEngine`
   - Protocol: in-process

3. **Load matching deals**: The query engine builds a Postgres query (with optional Mongo fallback for legacy paths) and loads matching deal records via the Deal Persistence Gateway.
   - From: `dealQueryAndFilterEngine`
   - To: `dealPersistenceGateway` -> `continuumMarketingDealDb`
   - Protocol: JDBC (JDBI)

4. **Request inventory enrichment**: The query engine passes the deal result set to the Inventory Aggregation Service for real-time inventory status enrichment.
   - From: `dealQueryAndFilterEngine`
   - To: `inventoryAggregationService`
   - Protocol: in-process

5. **Fan out to inventory services**: The Inventory Aggregation Service determines which inventory services to call based on deal types in the result set, then calls the relevant services via External Service Adapters (Retrofit clients).
   - From: `inventoryAggregationService`
   - To: `externalAdapters` -> `continuumVoucherInventoryApi`, `continuumGoodsInventoryService`, `continuumThirdPartyInventoryService`, `continuumTravelInventoryService`, `continuumGLiveInventoryService`, `continuumInventoryService`
   - Protocol: HTTP (Retrofit)

6. **Merge inventory status**: The Inventory Aggregation Service merges the inventory responses into the deal payloads, adding option-level availability status (available, sold_out, limited) per deal.
   - From: `inventoryAggregationService`
   - To: `dealQueryAndFilterEngine` (return)
   - Protocol: in-process

7. **Transform and return response**: The query engine applies final response transformations and returns the enriched deal payload to Deal API Resources, which sends the HTTP response.
   - From: `dealQueryAndFilterEngine`
   - To: `dealApiResources` -> API Client
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PostgreSQL query failure | Return HTTP 500 | No deal data returned; client must retry |
| Individual inventory service timeout | That service's status set to "unknown"; remaining services still merged | Partial inventory data returned; response includes degradation indicator |
| All inventory services unavailable | Inventory enrichment skipped entirely | Deal data returned without inventory status; response includes degradation indicator |
| Malformed query parameters | Return HTTP 400 with validation errors | Client must fix and retry |
| Large result set causing slow query | Query engine applies pagination limits | Response truncated to page size; client paginates |

## Sequence Diagram

```
Client -> dealApiResources: GET /deals?division=X&inventory=true
dealApiResources -> dealQueryAndFilterEngine: query(params)
dealQueryAndFilterEngine -> dealPersistenceGateway: loadDeals(filters)
dealPersistenceGateway -> continuumMarketingDealDb: SELECT deals WHERE ...
continuumMarketingDealDb --> dealPersistenceGateway: deal records
dealPersistenceGateway --> dealQueryAndFilterEngine: deals[]
dealQueryAndFilterEngine -> inventoryAggregationService: enrich(deals[])
inventoryAggregationService -> externalAdapters: fetchVoucherInventory(deal_ids)
externalAdapters -> continuumVoucherInventoryApi: GET /inventory?deals=...
continuumVoucherInventoryApi --> externalAdapters: voucher status
inventoryAggregationService -> externalAdapters: fetchGoodsInventory(deal_ids)
externalAdapters -> continuumGoodsInventoryService: GET /inventory?deals=...
continuumGoodsInventoryService --> externalAdapters: goods status
inventoryAggregationService -> externalAdapters: fetchThirdPartyInventory(deal_ids)
externalAdapters -> continuumThirdPartyInventoryService: GET /inventory?deals=...
continuumThirdPartyInventoryService --> externalAdapters: third-party status
inventoryAggregationService -> externalAdapters: fetchTravelInventory(deal_ids)
externalAdapters -> continuumTravelInventoryService: GET /inventory?deals=...
continuumTravelInventoryService --> externalAdapters: travel status
inventoryAggregationService -> externalAdapters: fetchGLiveInventory(deal_ids)
externalAdapters -> continuumGLiveInventoryService: GET /inventory?deals=...
continuumGLiveInventoryService --> externalAdapters: glive status
externalAdapters --> inventoryAggregationService: all inventory responses
inventoryAggregationService --> dealQueryAndFilterEngine: deals[] with inventory
dealQueryAndFilterEngine --> dealApiResources: transformed response
dealApiResources --> Client: 200 OK {deals with inventory}
```

## Related

- Architecture dynamic view: `dynamic-mds-deal-query-flow`
- Related flows: [Deal Enrichment Pipeline](deal-enrichment-pipeline.md), [Deal Event Consumption](deal-event-consumption.md)
