---
service: "deal-performance-api-v2"
title: "Deal Option Performance Metrics Query"
generated: "2026-03-03"
type: flow
flow_name: "deal-option-performance-metrics-query"
flow_type: synchronous
trigger: "POST /getDealOptionPerformanceMetrics"
participants:
  - "continuumDealPerformanceApiV2_dealOptionPerformanceApiV2Resource"
  - "continuumDealPerformanceApiV2_dealOptionPerformanceDao"
  - "continuumDealPerformancePostgres"
architecture_ref: "dynamic-deal-performance-query-flow"
---

# Deal Option Performance Metrics Query

## Summary

This flow handles `POST /getDealOptionPerformanceMetrics` requests, returning aggregated purchase counts and activation counts for deal options within a specified time window. The target database table is selected based on `timeGranularity`: `HOURLY` routes to `deal_option_performance_hourly`, `DAILY` routes to `deal_option_performance_daily`. Results can be further grouped by caller-specified columns.

## Trigger

- **Type**: api-call
- **Source**: External consumer (Marketing analytics)
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (caller) | Sends `POST /getDealOptionPerformanceMetrics` with deal UUID, time range, granularity, and groupBy fields | External |
| `DealOptionPerformanceApiV2Resource` | Receives HTTP request, delegates to DAO, returns response | `continuumDealPerformanceApiV2_dealOptionPerformanceApiV2Resource` |
| `DealOptionPerformanceDAO` | Dynamically builds SQL query based on granularity and groupBy columns, executes query | `continuumDealPerformanceApiV2_dealOptionPerformanceDao` |
| Deal Performance PostgreSQL | Executes the option performance query and returns aggregated rows | `continuumDealPerformancePostgres` |

## Steps

1. **Receives option performance request**: Consumer sends `POST /getDealOptionPerformanceMetrics` with JSON body containing `dealId` (UUID, required), `fromTime` (datetime, required), `toTime` (datetime, required), `timeGranularity` (HOURLY or DAILY, required), `groupBy` (array of column names, required).
   - From: Consumer
   - To: `continuumDealPerformanceApiV2_dealOptionPerformanceApiV2Resource`
   - Protocol: REST/HTTP

2. **Delegates to DAO**: The resource passes all parameters to `DealOptionPerformanceDAO.getDealOptionPerformance()`.
   - From: `continuumDealPerformanceApiV2_dealOptionPerformanceApiV2Resource`
   - To: `continuumDealPerformanceApiV2_dealOptionPerformanceDao`
   - Protocol: Direct (in-process)

3. **Selects target table**: The DAO inspects `timeGranularity`. If `HOURLY`, it selects `deal_option_performance_hourly`; if `DAILY`, it selects `deal_option_performance_daily`.
   - From: `continuumDealPerformanceApiV2_dealOptionPerformanceDao`
   - To: In-process
   - Protocol: Direct

4. **Builds dynamic SQL**: The DAO constructs a SQL string: `SELECT [groupBy columns,] sum(purchases_count) AS purchases, sum(activations_count) AS activations FROM <table> WHERE deal_id = :dealId AND time_bucket >= :fromTime AND time_bucket <= :toTime [GROUP BY groupBy columns]`. GroupBy columns are appended dynamically if provided.
   - From: `continuumDealPerformanceApiV2_dealOptionPerformanceDao`
   - To: In-process SQL builder
   - Protocol: Direct

5. **Executes query**: The DAO binds `dealId`, `fromTime`, `toTime` and executes the query via JDBI on the default (read-only) connection.
   - From: `continuumDealPerformanceApiV2_dealOptionPerformanceDao`
   - To: `continuumDealPerformancePostgres`
   - Protocol: JDBC/PostgreSQL

6. **Maps and returns results**: Result rows are mapped to `List<Map<String, Object>>`. A `DealOptionPerformanceMetric` wrapper is built and returned as HTTP 200 JSON.
   - From: `continuumDealPerformanceApiV2_dealOptionPerformanceApiV2Resource`
   - To: Consumer
   - Protocol: REST/HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required fields (`dealId`, `fromTime`, `toTime`, `timeGranularity`, `groupBy`) | JAX-RS validation rejects | HTTP 4xx |
| Database query failure | JDBI propagates exception | HTTP 5xx |
| No matching rows | Empty `metrics` list in response | HTTP 200 |

## Sequence Diagram

```
Consumer -> DealOptionPerformanceApiV2Resource: POST /getDealOptionPerformanceMetrics (dealId, fromTime, toTime, timeGranularity, groupBy[])
DealOptionPerformanceApiV2Resource -> DealOptionPerformanceDAO: getDealOptionPerformance(dealId, fromTime, toTime, timeGranularity, groupByColumns)
DealOptionPerformanceDAO -> DealOptionPerformanceDAO: selectTable(timeGranularity) -> deal_option_performance_daily|hourly
DealOptionPerformanceDAO -> DealOptionPerformanceDAO: buildSqlQuery(tableName, groupByColumns)
DealOptionPerformanceDAO -> PostgreSQL: SELECT [groupBy,] sum(purchases_count), sum(activations_count) FROM deal_option_performance_<granularity> WHERE deal_id=:dealId AND time_bucket BETWEEN :fromTime AND :toTime [GROUP BY groupBy]
PostgreSQL --> DealOptionPerformanceDAO: aggregated rows
DealOptionPerformanceDAO -> DealOptionPerformanceDAO: mapToMap() -> List<Map<String, Object>>
DealOptionPerformanceDAO --> DealOptionPerformanceApiV2Resource: DealOptionPerformanceMetric
DealOptionPerformanceApiV2Resource --> Consumer: HTTP 200 DealOptionPerformanceMetric (JSON)
```

## Related

- Architecture dynamic view: `dynamic-deal-performance-query-flow`
- Related flows: [Deal Performance Metrics Query](deal-performance-metrics-query.md), [Deal Attribute Metrics Query](deal-attribute-metrics-query.md)
