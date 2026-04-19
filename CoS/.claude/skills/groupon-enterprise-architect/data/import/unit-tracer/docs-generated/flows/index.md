---
service: "unit-tracer"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Unit Tracer.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Unit Report Generation](unit-report-generation.md) | synchronous | `GET /unit?unitIds=` or `GET /api/unit?unitIds=` HTTP request | Core flow: validates unit ID, fans out to all upstream services, assembles and returns a complete unit report |
| [Inventory Service Fallback Chain](inventory-service-fallback-chain.md) | synchronous | Invoked during unit report generation | Queries TPIS, then VIS, then Groupon Live in sequence until a unit is found |
| [Accounting Data Retrieval](accounting-data-retrieval.md) | synchronous | Invoked during unit report generation after UUID is resolved | Fetches unit financial details and vendor payment schedules from Accounting Service |
| [Ledger Lifecycle Retrieval](ledger-lifecycle-retrieval.md) | synchronous | Invoked during unit report generation after UUID is resolved | Fetches message-to-ledger lifecycle history for the unit |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The unit report generation flow spans five internal services. The architecture dynamic view is registered as `dynamic-unit-tracer-report-flow` in the Structurizr DSL (`structurizr/import/unit-tracer/architecture/views/dynamics/unitTracerReportFlow.dsl`). This view covers:

- `continuumUnitTracerService` → `continuumThirdPartyInventoryService`: Queries inventory units
- `continuumUnitTracerService` → `continuumVoucherInventoryService`: Queries inventory units (fallback)
- `continuumUnitTracerService` → `continuumAccountingService`: Fetches unit and vendor schedule data
