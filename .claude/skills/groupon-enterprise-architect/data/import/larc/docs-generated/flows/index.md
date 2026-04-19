---
service: "larc"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Travel Lowest Available Rate Calculator (LARC).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [QL2 Feed Ingestion](ql2-feed-ingestion.md) | scheduled | FTP Monitor Worker polls QL2 FTP server on configured interval | Discovers, downloads, and loads QL2 CSV pricing files into the LARC database |
| [LAR Computation and Rate Update](lar-computation-rate-update.md) | scheduled | Live Pricing Worker processes queued live pricing jobs after file ingestion | Computes lowest available nightly rates and publishes updates to Inventory Service |
| [On-Demand LAR Send](on-demand-lar-send.md) | synchronous | API call from eTorch or extranet app | Triggers immediate LAR calculation and delivery to Inventory Service for a specific rate plan |
| [Hotel and Rate Description Management](hotel-rate-description-management.md) | synchronous | API call from eTorch or extranet app | Creates/updates hotel records and maps QL2 rate descriptions to Groupon room types |
| [Nightly LAR Archive](nightly-lar-archive.md) | scheduled | Table Archive Worker runs on configured interval | Purges stale NightlyLar records to the archive table based on feature flag settings |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

- **QL2 Feed Ingestion** spans `thirdPartyInventory` (QL2 FTP) and `continuumTravelLarcService` — see [QL2 Feed Ingestion](ql2-feed-ingestion.md) and the DSL dynamic view `dynamic-larc-rate-update-flow`
- **LAR Computation and Rate Update** spans `continuumTravelLarcService`, `continuumDealCatalogService`, `continuumTravelInventoryService`, and `continuumTravelLarcDatabase` — the central architecture dynamic view `dynamic-larc-rate-update-flow` documents the cross-service path
