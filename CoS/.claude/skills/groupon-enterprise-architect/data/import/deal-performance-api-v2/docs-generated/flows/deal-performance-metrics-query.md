---
service: "deal-performance-api-v2"
title: "Deal Performance Metrics Query"
generated: "2026-03-03"
type: flow
flow_name: "deal-performance-metrics-query"
flow_type: synchronous
trigger: "POST /getDealPerformanceMetrics"
participants:
  - "continuumDealPerformanceApiV2_dealPerformanceApiV2Resource"
  - "continuumDealPerformanceApiV2_dealPerformanceDao"
  - "continuumDealPerformancePostgres"
architecture_ref: "dynamic-deal-performance-query-flow"
---

# Deal Performance Metrics Query

## Summary

This flow handles inbound `POST /getDealPerformanceMetrics` requests from consumers such as Marketing tools and the Search/Ranking pipeline. The API resource validates the request, delegates to the DAO to construct and execute a dynamically generated SQL query against the PostgreSQL database, then assembles and returns a structured metrics response. The response contains one `DealPerformanceMetric` entry per requested metric, each containing grouped time-series data points.

## Trigger

- **Type**: api-call
- **Source**: External consumer (Marketing analytics, Search/Ranking pipeline)
- **Frequency**: On-demand, up to ~800 TPS target throughput

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (caller) | Sends `POST /getDealPerformanceMetrics` with deal UUID, time range, time granularity, and list of metric requests | External |
| `DealPerformanceApiV2Resource` | Receives HTTP request, validates request body, delegates to DAO, assembles response | `continuumDealPerformanceApiV2_dealPerformanceApiV2Resource` |
| `DealPerformanceDAO` | Selects DB connection (primary vs. replica), renders SQL template, executes query, maps result rows to metric objects | `continuumDealPerformanceApiV2_dealPerformanceDao` |
| Deal Performance PostgreSQL | Executes the parameterized CTE SQL query and returns raw aggregated rows | `continuumDealPerformancePostgres` |

## Steps

1. **Receives performance metrics request**: Consumer sends `POST /getDealPerformanceMetrics` with JSON body containing `dealId` (UUID), `fromTime`, `toTime`, `timeGranularity` (HOURLY or DAILY), and `metrics` array (each with `name`, `groupBy`, optional `groupAlias`).
   - From: Consumer
   - To: `continuumDealPerformanceApiV2_dealPerformanceApiV2Resource`
   - Protocol: REST/HTTP

2. **Validates request**: JAX-RS applies `@NotNull @Valid` constraints on the request body. Invalid requests are rejected before the DAO is invoked.
   - From: `continuumDealPerformanceApiV2_dealPerformanceApiV2Resource`
   - To: JAX-RS validation layer (in-process)
   - Protocol: Direct

3. **Selects database connection**: `DealPerformanceDAO.getDealPerformance()` checks the `shouldUsePrimaryDb` flag. If `true` and a primary JDBI instance is configured, the primary (read-write) connection is used; otherwise the default read-only replica connection is used.
   - From: `continuumDealPerformanceApiV2_dealPerformanceApiV2Resource`
   - To: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - Protocol: Direct (in-process)

4. **Selects and renders SQL template**: If `shouldUseNewSQL=true` and only one metric is requested, the optimized template (`OptimizedDealPerformanceDAO.sql.stg`) is used; otherwise the standard CTE-union template (`DealPerformanceDAO.sql.stg`) is rendered. StringTemplate4 generates a CTE query that unions sub-queries per metric, each parameterized by `event_type`, `groupBy` columns, and `timeGranularity` (selecting from `deal_performance_daily` or `deal_performance_hourly`).
   - From: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - To: StringTemplate4 rendering (in-process)
   - Protocol: Direct

5. **Executes parameterized SQL query**: The DAO binds `dealId`, `fromTime`, `toTime` and submits the rendered SQL to the PostgreSQL database via JDBI. The database scans the appropriate `deal_performance_<granularity>` table and returns aggregated rows containing `metric_value`, `count_type`, `group_fields`, and `metric_index`.
   - From: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - To: `continuumDealPerformancePostgres`
   - Protocol: JDBC/PostgreSQL

6. **Maps result rows to metric objects**: `DealPerformanceResultRowMapper` maps each raw result row to a `DealPerformanceResultRow`. Rows are grouped by `metric_index` to reconstruct per-metric result sets.
   - From: `continuumDealPerformancePostgres`
   - To: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - Protocol: JDBC result set

7. **Applies brand expansion**: For any metric requesting `groupBy=BRAND`, the DAO expands result rows to ensure both `groupon` and `livingsocial` brand entries appear for every data point, inserting zero-value rows for missing brands (MIS-527 requirement).
   - From: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - To: In-process
   - Protocol: Direct

8. **Assembles and returns response**: The resource builds a `DealPerformanceMetrics` response object containing `dealId`, `fromTime`, `toTime`, `timeGranularity`, and the list of `DealPerformanceMetric` objects, then returns HTTP 200.
   - From: `continuumDealPerformanceApiV2_dealPerformanceApiV2Resource`
   - To: Consumer
   - Protocol: REST/HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid request body (missing required fields) | JAX-RS `@Valid` / `@NotNull` raises validation error | HTTP 4xx response |
| Empty `metrics` array | DAO returns empty list immediately (no DB call) | HTTP 200 with empty metrics list |
| Database query exception | DAO logs error with `dealId` context and rethrows | HTTP 5xx response to consumer |
| Database unavailable | JDBI connection pool throws; propagates to HTTP layer | HTTP 5xx response; no fallback |

## Sequence Diagram

```
Consumer -> DealPerformanceApiV2Resource: POST /getDealPerformanceMetrics (dealId, fromTime, toTime, timeGranularity, metrics[])
DealPerformanceApiV2Resource -> DealPerformanceDAO: getDealPerformance(dealId, fromTime, toTime, timeGranularity, requests, shouldUsePrimaryDb, shouldUseNewSQL)
DealPerformanceDAO -> DealPerformanceDAO: selectJdbi(shouldUsePrimaryDb)
DealPerformanceDAO -> DealPerformanceDAO: renderSQLTemplate(requests, timeGranularity)
DealPerformanceDAO -> PostgreSQL: SELECT ... FROM deal_performance_<granularity> WHERE deal_id = :dealId AND time_bucket BETWEEN :fromTime AND :toTime
PostgreSQL --> DealPerformanceDAO: result rows (metric_value, count_type, group_fields, metric_index)
DealPerformanceDAO -> DealPerformanceDAO: mapRows(), applyBrandExpansion(), buildDealPerformanceMetrics()
DealPerformanceDAO --> DealPerformanceApiV2Resource: List<DealPerformanceMetric>
DealPerformanceApiV2Resource --> Consumer: HTTP 200 DealPerformanceMetrics (JSON)
```

## Related

- Architecture dynamic view: `dynamic-deal-performance-query-flow`
- Related flows: [Deal Attribute Metrics Query](deal-attribute-metrics-query.md), [Deal Option Performance Metrics Query](deal-option-performance-metrics-query.md), [Database Routing and SQL Template Rendering](database-routing-sql-rendering.md)
