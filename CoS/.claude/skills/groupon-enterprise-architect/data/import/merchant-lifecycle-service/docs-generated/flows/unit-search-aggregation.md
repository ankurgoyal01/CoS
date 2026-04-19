---
service: "merchant-lifecycle-service"
title: "Unit Search Aggregation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "unit-search-aggregation"
flow_type: synchronous
trigger: "API call — POST /units/v1/search"
participants:
  - "continuumMlsRinService"
  - "unitIndexPostgres"
  - "continuumVoucherInventoryService"
  - "continuumGLiveInventoryService"
  - "continuumInventoryService"
  - "continuumBhuvanService"
  - "continuumM3MerchantService"
  - "continuumDealCatalogService"
  - "continuumPricingService"
architecture_ref: "components-mls-rin-service"
---

# Unit Search Aggregation

## Summary

This flow handles inbound unit search requests via `POST /units/v1/search`. The `continuumMlsRinService` reads pre-materialized unit index data from `unitIndexPostgres`, then enriches results by fanning out to multiple upstream services — voucher inventory, GLive, FIS, geo, merchant details, pricing, and deal catalog. The enriched, merged response is returned to the caller. The flow uses RxJava 3 for concurrent upstream fan-out to minimize total latency.

## Trigger

- **Type**: api-call
- **Source**: External caller (merchant portal, internal tooling) sends `POST /units/v1/search`
- **Frequency**: On demand, per request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller | Initiates unit search request | — |
| `rinApiLayer` | Receives request and routes to unit search domain | `continuumMlsRinService` |
| `rinUnitSearchDomain` | Orchestrates search, enrichment, and rendering | `continuumMlsRinService` |
| `rinDataAccess` | Reads unit index records from local PostgreSQL | `continuumMlsRinService` |
| `unitIndexPostgres` | Source of pre-materialized unit search state | `unitIndexPostgres` |
| `rinExternalGateway` | Issues fan-out HTTP calls to upstream services | `continuumMlsRinService` |
| `continuumVoucherInventoryService` | Provides voucher inventory details | `continuumVoucherInventoryService` |
| `continuumGLiveInventoryService` | Provides GLive inventory data | `continuumGLiveInventoryService` |
| `continuumInventoryService` | Provides FIS-backed inventory product payloads | `continuumInventoryService` |
| `continuumBhuvanService` | Resolves geo places and divisions | `continuumBhuvanService` |
| `continuumM3MerchantService` | Provides merchant account details | `continuumM3MerchantService` |
| `continuumDealCatalogService` | Provides deal catalog and template data | `continuumDealCatalogService` |
| `continuumPricingService` | Provides pricing context and ILS program details | `continuumPricingService` |

## Steps

1. **Receive search request**: Caller sends `POST /units/v1/search` with search criteria.
   - From: `caller`
   - To: `rinApiLayer`
   - Protocol: REST/HTTP

2. **Route to unit search domain**: `rinApiLayer` delegates to `rinUnitSearchDomain`.
   - From: `rinApiLayer`
   - To: `rinUnitSearchDomain`
   - Protocol: direct (in-process)

3. **Query local unit index**: `rinUnitSearchDomain` calls `rinDataAccess` to retrieve matching unit records from `unitIndexPostgres`.
   - From: `rinUnitSearchDomain`
   - To: `rinDataAccess` -> `unitIndexPostgres`
   - Protocol: JDBI/PostgreSQL

4. **Fan out to upstream enrichment services**: `rinUnitSearchDomain` issues concurrent HTTP requests via `rinExternalGateway` to voucher inventory, GLive, FIS inventory, geo, merchant, deal catalog, and pricing services using RxJava 3 reactive composition.
   - From: `rinExternalGateway`
   - To: `continuumVoucherInventoryService`, `continuumGLiveInventoryService`, `continuumInventoryService`, `continuumBhuvanService`, `continuumM3MerchantService`, `continuumDealCatalogService`, `continuumPricingService`
   - Protocol: REST/HTTP

5. **Merge and render results**: `rinUnitSearchDomain` merges local index data with upstream enrichments, applies rendering logic, and assembles the response payload.
   - From: `rinUnitSearchDomain`
   - To: `rinApiLayer`
   - Protocol: direct (in-process)

6. **Return response**: `rinApiLayer` returns the aggregated unit search response to the caller.
   - From: `rinApiLayer`
   - To: `caller`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `unitIndexPostgres` unavailable | JDBC connection failure propagates | HTTP 5xx returned to caller |
| Upstream enrichment service unavailable | RxJava error handling; missing enrichment fields omitted | Partial result returned; enrichment fields absent |
| FIS client error | `rinExternalGateway` error handling; inventory data absent from result | Partial result returned |
| Request timeout | Dropwizard/JTier request timeout | HTTP 504 or 5xx returned to caller |

## Sequence Diagram

```
Caller -> rinApiLayer: POST /units/v1/search
rinApiLayer -> rinUnitSearchDomain: route search request
rinUnitSearchDomain -> rinDataAccess: query unit index
rinDataAccess -> unitIndexPostgres: SELECT unit records
unitIndexPostgres --> rinDataAccess: unit rows
rinDataAccess --> rinUnitSearchDomain: unit records
rinUnitSearchDomain -> rinExternalGateway: fan out enrichment requests (concurrent)
rinExternalGateway -> continuumVoucherInventoryService: GET voucher inventory
rinExternalGateway -> continuumGLiveInventoryService: GET GLive inventory
rinExternalGateway -> continuumInventoryService: GET FIS inventory products
rinExternalGateway -> continuumBhuvanService: GET geo places
rinExternalGateway -> continuumM3MerchantService: GET merchant details
rinExternalGateway -> continuumDealCatalogService: GET deal catalog
rinExternalGateway -> continuumPricingService: GET pricing context
rinExternalGateway --> rinUnitSearchDomain: enrichment responses
rinUnitSearchDomain -> rinUnitSearchDomain: merge and render results
rinUnitSearchDomain --> rinApiLayer: search response payload
rinApiLayer --> Caller: HTTP 200 aggregated unit search results
```

## Related

- Architecture component view: `components-mls-rin-service`
- Related flows: [Merchant Insights Aggregation](merchant-insights-aggregation.md), [Unit Inventory State Sync](unit-inventory-state-sync.md)
