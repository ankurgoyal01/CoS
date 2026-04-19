---
service: "tpis-inventory-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Third Party Inventory Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Partner Inventory Sync](partner-inventory-sync.md) | synchronous | Partner inventory update | Ingests inventory data from external partner platforms and persists to local database |
| [Inventory Query](inventory-query.md) | synchronous | API request | Internal services query TPIS for third-party inventory products, units, and availability |
| [Data Replication](data-replication.md) | batch | Scheduled | Replicates inventory data from MySQL to EDW and BigQuery for analytics |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Deal Availability Check**: Deal Service and Deal Management API query TPIS as part of the deal availability pipeline to determine if third-party inventory is available for a given deal.
- **TTD Feed Generation**: MDS Feed Job reads TPIS availability data as part of generating Things To Do (TTD) syndication feeds.
- **Unit Tracing**: Unit Tracer queries TPIS inventory units as part of building comprehensive unit trace reports across inventory services.
- **Message-to-Ledger Processing**: Message2Ledger fetches TPIS unit/product details when processing applicable financial ledger entries.
- **Booking Flow**: iTier 3PIP and MyGroupons use TPIS booking data as part of the end-to-end third-party booking experience.
