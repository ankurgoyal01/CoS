---
service: "deal-performance-api-v2"
title: "Database Routing and SQL Template Rendering"
generated: "2026-03-03"
type: flow
flow_name: "database-routing-sql-rendering"
flow_type: synchronous
trigger: "Internal — invoked on every DealPerformanceDAO query"
participants:
  - "continuumDealPerformanceApiV2_dealPerformanceDao"
  - "continuumDealPerformancePostgres"
architecture_ref: "dynamic-deal-performance-query-flow"
---

# Database Routing and SQL Template Rendering

## Summary

This internal flow describes how `DealPerformanceDAO` selects the correct database connection and SQL template on every performance metrics request. Two routing decisions are made per request: (1) whether to use the primary (read-write) or replica (read-only) JDBI connection, and (2) whether to use the standard multi-metric CTE SQL template or the optimized single-metric SQL template. These decisions are controlled by per-request boolean query parameters, enabling consumers to tune query routing without service redeployment.

## Trigger

- **Type**: api-call (internal)
- **Source**: `DealPerformanceApiV2Resource` on every `POST /getDealPerformanceMetrics` call
- **Frequency**: Per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `DealPerformanceDAO` | Evaluates routing flags, selects JDBI instance, selects and renders SQL template | `continuumDealPerformanceApiV2_dealPerformanceDao` |
| Deal Performance PostgreSQL (primary) | Accepts connections from primary JDBI pool | `continuumDealPerformancePostgres` |
| Deal Performance PostgreSQL (replica) | Accepts connections from default session JDBI pool | `continuumDealPerformancePostgres` |

## Steps

1. **Evaluates `shouldUsePrimaryDb` flag**: `DealPerformanceDAO.getJdbi(shouldUsePrimaryDb)` checks whether the flag is `true` and a primary JDBI instance is present. If both conditions are met, the primary connection is returned; otherwise the default (read-only replica) connection is used.
   - From: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - To: In-process (JDBI instance selection)
   - Protocol: Direct

2. **Evaluates `shouldUseNewSQL` flag and metric count**: If `shouldUseNewSQL=true` AND the request contains exactly one metric (`requests.size() == 1`), the optimized template is selected. Otherwise the standard multi-metric template is selected.
   - From: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - To: In-process
   - Protocol: Direct

3. **Loads StringTemplate4 group**: The DAO loads the appropriate `.sql.stg` file:
   - Standard path: `sqlTemplates/DealPerformanceDAO.sql.stg` — renders a CTE that unions one sub-query per metric request, each selecting from `deal_performance_<timeGranularity>` and filtering by `event_type`
   - Optimized path: `sqlTemplates/OptimizedDealPerformanceDAO.sql.stg` — renders a single flat SELECT for one metric, without the CTE overhead
   - From: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - To: StringTemplate4 engine (in-process)
   - Protocol: Direct

4. **Registers custom renderers**: The DAO registers two `AttributeRenderer` implementations:
   - `MetricNameRenderer` — maps `MetricName` enum to its SQL `event_type` string (e.g., `PURCHASES` -> `dealPurchase`)
   - `GroupingFieldRenderer` — maps `GroupingField` enum to its SQL column name (e.g., `OPTION_ID` -> `deal_option_id`, `TIMESTAMP` -> ISO 8601 timestamp expression)
   - From: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - To: StringTemplate4 engine
   - Protocol: Direct

5. **Renders SQL string**: The template instance is populated with the `requests` list (or single `request`) and `timeGranularity` value, producing a complete parameterized SQL string with `:dealId`, `:fromTime`, `:toTime` bind parameter placeholders.
   - From: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - To: In-process
   - Protocol: Direct

6. **Executes rendered SQL**: The rendered SQL string is submitted to the selected JDBI connection with bound parameters.
   - From: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - To: `continuumDealPerformancePostgres`
   - Protocol: JDBC/PostgreSQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `shouldUsePrimaryDb=true` but no primary JDBI configured | Falls back to replica connection gracefully | Query executes on replica |
| `shouldUseNewSQL=true` with multiple metrics | Optimized template is NOT selected; standard template is used | Correct behavior, no error |
| Template rendering error | Exception propagates from StringTemplate4 | DAO logs and rethrows; HTTP 5xx |
| JDBC connection failure | JDBI throws; DAO logs with `dealId` context | HTTP 5xx |

## Sequence Diagram

```
DealPerformanceApiV2Resource -> DealPerformanceDAO: getDealPerformance(dealId, fromTime, toTime, timeGranularity, requests, shouldUsePrimaryDb, shouldUseNewSQL)
DealPerformanceDAO -> DealPerformanceDAO: getJdbi(shouldUsePrimaryDb) -> primaryJdbi | jdbi
DealPerformanceDAO -> DealPerformanceDAO: selectTemplate(shouldUseNewSQL, requests.size) -> OptimizedDealPerformanceDAO.sql.stg | DealPerformanceDAO.sql.stg
DealPerformanceDAO -> StringTemplate4: load template group, register MetricNameRenderer + GroupingFieldRenderer
StringTemplate4 -> DealPerformanceDAO: rendered SQL string
DealPerformanceDAO -> PostgreSQL: execute(sql).bind(dealId, fromTime, toTime)
PostgreSQL --> DealPerformanceDAO: result rows
```

## Related

- Architecture dynamic view: `dynamic-deal-performance-query-flow`
- Related flows: [Deal Performance Metrics Query](deal-performance-metrics-query.md)
