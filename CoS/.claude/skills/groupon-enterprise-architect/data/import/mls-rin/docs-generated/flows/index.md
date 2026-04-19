---
service: "mls-rin"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for MLS RIN (Merchant Lifecycle System Read Interface).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal List Query](deal-list-query.md) | synchronous | API call to `GET /v1/deals` or `POST /v1/deals` | Fetches and enriches a paginated list of deals from the deal index database for a merchant |
| [Unit Search](unit-search.md) | synchronous | API call to `POST /units/v1/search` or `POST /units/v2/search` | Orchestrates federated unit search across one or more inventory services with enrichment |
| [Metrics Retrieval](metrics-retrieval.md) | synchronous | API call to `GET /v1/metrics` | Reads aggregated marketing metrics from the metrics database for a set of deal UUIDs |
| [CLO Transactions Query](clo-transactions-query.md) | synchronous | API call to `POST /v2/clotransactions/*` | Retrieves CLO transaction data (itemized list, visits, or new customers) for a date range |
| [Merchant Risk Lookup](merchant-risk-lookup.md) | synchronous | API call to `GET /v1/merchant_risk/{merchant_id}` | Retrieves merchant risk status from the Yang DB when the risk module is enabled |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Deal List Query** fans out to `continuumMarketingDealService` (MANA) for deal index data and optionally to `continuumDealCatalogService`, `continuumBhuvanService`, `continuumUgcService` for enrichment fields
- **Unit Search** is the most complex cross-service flow, fanning out to multiple federated inventory services (`continuumVoucherInventoryService`, `continuumGLiveInventoryService`, `continuumInventoryService`) and enrichment services (`continuumOrdersService`, `continuumPricingService`, `continuumM3MerchantService`)
- All flows are synchronous and request-driven; there are no scheduled or batch flows owned by this service
