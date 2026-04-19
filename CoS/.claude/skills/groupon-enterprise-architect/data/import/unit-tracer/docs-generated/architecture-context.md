---
service: "unit-tracer"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumUnitTracerService"]
---

# Architecture Context

## System Context

Unit Tracer is a container within the `continuumSystem` (Groupon's Continuum platform). It sits in the Finance Engineering domain and acts purely as a read-only aggregation tool: it accepts lookup requests from internal users or tooling, fans out to five downstream Continuum service APIs, and returns consolidated unit history reports. It has no persistent state of its own and does not participate in any event-driven pipelines. Its primary relationships are outbound HTTP calls to inventory, accounting, and ledger services.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Unit Tracer Service | `continuumUnitTracerService` | Service | Java / Dropwizard (JTier) | 1.0.x | Dropwizard JTier service that builds unit history reports by aggregating inventory, accounting, and ledger data. |

## Components by Container

### Unit Tracer Service (`continuumUnitTracerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `UnitTracerResource` | Renders HTML views and handles unit search requests via `GET /` and `GET /unit` | JAX-RS Resource |
| `ApiResource` | Returns unit report data as JSON via `GET /api/unit` | JAX-RS Resource |
| `UnitReportBuilder` | Orchestrates building of unit reports; validates and normalizes unit IDs; delegates to section builders | Service |
| `InventoryServicesReportSectionBuilder` | Queries TPIS, VIS, and Groupon Live sequentially; populates inventory section of the report | Service |
| `AccountingServiceSectionBuilder` | Fetches unit financial data and vendor payment schedules from Accounting Service | Service |
| `MessageToLedgerReportSectionBuilder` | Fetches unit lifecycle message history from Message to Ledger | Service |
| `ThirdPartyInventoryServiceClient` | Retrofit HTTP client targeting `GET /inventory/v1/units` on Third Party Inventory Service | Retrofit Client |
| `VoucherInventoryServiceClient` | Retrofit HTTP client targeting `GET /inventory/v1/units` on Voucher Inventory Service | Retrofit Client |
| `GrouponLiveInventoryServiceClient` | Retrofit HTTP client targeting `GET /inventory/v1/units` on Groupon Live Inventory Service | Retrofit Client |
| `AccountingServiceClient` | Retrofit HTTP client targeting `GET /api/v3/units/{id}` and `GET api/v3/vendors/{vendorId}/schedules` | Retrofit Client |
| `MessageToLedgerClient` | Retrofit HTTP client targeting `GET /admin/units/{unitId}/lifecycle` | Retrofit Client |
| `UnitTracerHealthCheck` | Dropwizard health check (math check — always healthy) | Health Check |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumUnitTracerService` | `continuumThirdPartyInventoryService` | Queries inventory units by UUID or Groupon code | REST/HTTP |
| `continuumUnitTracerService` | `continuumVoucherInventoryService` | Queries inventory units (fallback if TPIS returns no results) | REST/HTTP |
| `continuumUnitTracerService` | Groupon Live Inventory Service (stub) | Queries inventory units (second fallback) | REST/HTTP |
| `continuumUnitTracerService` | `continuumAccountingService` | Retrieves unit financial data and vendor payment schedules | REST/HTTP |
| `continuumUnitTracerService` | Message to Ledger (stub) | Retrieves unit lifecycle message history | REST/HTTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-unit-tracer-components`
- Dynamic flow: `dynamic-unit-tracer-report-flow`
