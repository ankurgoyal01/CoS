---
service: "gpn-data-api"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for GPN Data API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Attribution Details Request](attribution-details-request.md) | synchronous | POST /attribution/orders | Caller submits order IDs and date range; service enforces daily limit, batches BigQuery queries, and returns JSON attribution records |
| [Paginated Attribution Request](attribution-details-paginated.md) | synchronous | POST /attribution/orders/paginated | Caller requests attribution data page by page using BigQuery job tokens to avoid re-executing the query on subsequent pages |
| [Attribution CSV Export](attribution-csv-export.md) | synchronous | POST /attribution/orders/csv | Caller requests attribution data as a downloadable CSV file; same limit and BigQuery query path as the JSON endpoint |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Attribution Details Request flow is modelled as a dynamic view in the Structurizr architecture DSL: `dynamic-attributionDetailsFlow` (file: `architecture/views/dynamics/attribution-details-flow.dsl`).

This dynamic view covers the interaction between `attributionDetailsResource`, `attributionDetailsService`, `attributionQueryCountDao`, and `gpnDataApi_bigQueryService` within `continuumGpnDataApiService`.

The entry point from the external consumer (`sem-ui`) is captured in the stubs model: `attributionApiClients_unk_2f3c -> continuumGpnDataApiService`.
