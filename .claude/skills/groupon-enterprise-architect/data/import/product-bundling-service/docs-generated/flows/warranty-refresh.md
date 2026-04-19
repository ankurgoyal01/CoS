---
service: "product-bundling-service"
title: "Warranty Refresh"
generated: "2026-03-03"
type: flow
flow_name: "warranty-refresh"
flow_type: scheduled
trigger: "Quartz cron (daily) or manual POST /v1/bundles/refresh/warranty"
participants:
  - "pbsWarrantyJobOrchestrator"
  - "pbsDealCatalogSyncService"
  - "pbsInventoryAdapter"
  - "pbsApiResource"
  - "continuumDealCatalogService"
  - "continuumVoucherInventoryService"
  - "continuumGoodsInventoryService"
  - "continuumProductBundlingPostgres"
architecture_ref: "dynamic-pbs-warranty-refresh"
---

# Warranty Refresh

## Summary

The Warranty Refresh flow is a scheduled batch job that scans deals eligible for warranty bundles, fetches current inventory attributes from Voucher Inventory Service and Goods Inventory Service, computes warranty bundle values (eligible product + price range combinations), and then posts them as new warranty bundles via the internal PBS API. This keeps warranty bundle offerings current with inventory availability and pricing. The job runs once daily and can also be triggered manually.

## Trigger

- **Type**: schedule (also supports manual trigger)
- **Source**: Quartz scheduler (`BundlesRefreshScheduler`) — trigger `WarrantyBundlesRefreshTrigger`; also triggerable on demand via `POST /v1/bundles/refresh/warranty`
- **Frequency**: Daily (cron: `0 33 09 * * ?` in dev config)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Warranty Job Orchestrator | Quartz job entry point; orchestrates deal scanning, inventory fetching, and bundle posting | `pbsWarrantyJobOrchestrator` |
| Deal Catalog Sync Service | Retrieves deal and deal option metadata from Deal Catalog Service | `pbsDealCatalogSyncService` |
| Inventory Adapter | Fetches inventory attributes (pricing, shipping eligibility) from VIS and GIS | `pbsInventoryAdapter` |
| PBS API Resource | Receives internally-generated warranty bundle create requests | `pbsApiResource` |
| Deal Catalog Service | Source of deal and option metadata for eligible deals | `continuumDealCatalogService` |
| Voucher Inventory Service | Provides inventory product details for voucher deal options | `continuumVoucherInventoryService` |
| Goods Inventory Service | Provides inventory product details for goods deal options | `continuumGoodsInventoryService` |
| Product Bundling Postgres | Stores newly created warranty bundle records | `continuumProductBundlingPostgres` |

## Steps

1. **Trigger warranty refresh**: Quartz fires `WarrantyBundlesRefreshJob`, which delegates to the Warranty Job Orchestrator. The job scans all active deals whose product/deal-structure categories are in the configured `warrantyEligiblePdsCategories` list.
   - From: `Quartz scheduler`
   - To: `pbsWarrantyJobOrchestrator`
   - Protocol: Direct (Quartz job invocation)

2. **Retrieve eligible deal and option metadata from DCS**: For each candidate deal, the Warranty Job Orchestrator instructs Deal Catalog Sync Service to fetch deal details and option information from Deal Catalog Service.
   - From: `pbsWarrantyJobOrchestrator`
   - To: `pbsDealCatalogSyncService` → `continuumDealCatalogService`
   - Protocol: HTTP/JSON

3. **Fetch voucher inventory product details**: For voucher-type deal options, the Warranty Job Orchestrator instructs Inventory Adapter to call Voucher Inventory Service (`GET /inventory/v1/products`) to retrieve inventory attributes needed for warranty eligibility and pricing.
   - From: `pbsWarrantyJobOrchestrator`
   - To: `pbsInventoryAdapter` → `continuumVoucherInventoryService`
   - Protocol: HTTP/JSON

4. **Fetch goods inventory product details**: For goods-type deal options, the Inventory Adapter calls Goods Inventory Service (`GET /inventory/v1/products`) to retrieve inventory attributes.
   - From: `pbsWarrantyJobOrchestrator`
   - To: `pbsInventoryAdapter` → `continuumGoodsInventoryService`
   - Protocol: HTTP/JSON

5. **Compute warranty bundle values**: Warranty Job Orchestrator evaluates each option against `warrantyOptions` (min/max price ranges per product UUID) and `warrantyEligiblePdsCategories` to determine which warranty products are applicable and at what price points.
   - From: `pbsWarrantyJobOrchestrator` (internal computation)
   - To: (internal, no network call)
   - Protocol: Direct

6. **Post warranty bundles through internal PBS API**: For each deal with computed warranty bundle values, the Warranty Job Orchestrator calls PBS API Resource directly (using the `productBundlingServiceClient` Retrofit client pointing to the PBS VIP) to create the warranty bundles via `POST /v1/bundles/{dealUuid}/warranty`.
   - From: `pbsWarrantyJobOrchestrator`
   - To: `pbsApiResource`
   - Protocol: HTTP/JSON (internal PBS API call)

7. **Bundle create and DCS sync**: PBS API Resource processes the warranty bundle create request through the standard [Create Bundle](create-bundle.md) flow — persisting to Postgres and synchronizing the bundle node to Deal Catalog Service.
   - From: `pbsApiResource`
   - To: `pbsBundlingDomainService` → `pbsPersistenceAdapter` → `continuumProductBundlingPostgres`, `continuumDealCatalogService`
   - Protocol: JDBC/PostgreSQL, HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog Service unavailable | Job fails to retrieve deal metadata; logs exception | Warranty bundles not created for affected deals |
| Voucher Inventory Service unavailable | Job logs exception for affected options; may skip or fail | Warranty bundles not created for voucher options |
| Goods Inventory Service unavailable | Job logs exception for affected options; may skip or fail | Warranty bundles not created for goods options |
| No warranty options computed for a deal | Bundle create step is skipped for that deal | No warranty bundle posted; existing bundle remains |
| Internal PBS API call fails | Exception logged; job continues to next deal | Single deal's warranty bundle not updated |
| Manual refresh with invalid refreshType | Returns HTTP 400 | Job not started |

## Sequence Diagram

```
Quartz/Caller -> pbsWarrantyJobOrchestrator: Trigger WarrantyBundlesRefreshJob
pbsWarrantyJobOrchestrator -> pbsDealCatalogSyncService: Retrieve eligible deal and option metadata
pbsDealCatalogSyncService -> continuumDealCatalogService: GET deal search results and deal options
pbsWarrantyJobOrchestrator -> pbsInventoryAdapter: Fetch voucher inventory product details
pbsInventoryAdapter -> continuumVoucherInventoryService: GET /inventory/v1/products
pbsWarrantyJobOrchestrator -> pbsInventoryAdapter: Fetch goods inventory product details
pbsInventoryAdapter -> continuumGoodsInventoryService: GET /inventory/v1/products
pbsWarrantyJobOrchestrator -> pbsWarrantyJobOrchestrator: Compute warranty bundle values
pbsWarrantyJobOrchestrator -> pbsApiResource: POST /v1/bundles/{dealUuid}/warranty (internal)
pbsApiResource -> pbsBundlingDomainService: Validate and persist warranty bundles
pbsBundlingDomainService -> continuumProductBundlingPostgres: Write bundle records
pbsBundlingDomainService -> continuumDealCatalogService: PUT /deal_catalog/v3/deals/{dealUuid}/nodes/bundles
```

## Related

- Architecture dynamic view: `dynamic-pbs-warranty-refresh` (not yet defined in federated model)
- Related flows: [Create Bundle](create-bundle.md), [Recommendations Refresh](recommendations-refresh.md)
- See [Configuration](../configuration.md) for `warrantyEligiblePdsCategories` and `warrantyOptions` settings
