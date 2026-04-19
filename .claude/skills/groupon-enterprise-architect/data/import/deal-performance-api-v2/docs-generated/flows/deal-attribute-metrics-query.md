---
service: "deal-performance-api-v2"
title: "Deal Attribute Metrics Query"
generated: "2026-03-03"
type: flow
flow_name: "deal-attribute-metrics-query"
flow_type: synchronous
trigger: "GET /getDealAttributeMetrics"
participants:
  - "continuumDealPerformanceApiV2_dealAttributeApiV2Resource"
  - "continuumDealPerformanceApiV2_dealPerformanceDao"
  - "continuumDealPerformancePostgres"
architecture_ref: "dynamic-deal-performance-query-flow"
---

# Deal Attribute Metrics Query

## Summary

This flow handles `GET /getDealAttributeMetrics` requests, returning a daily time-series of deal attribute metrics such as Number of Bookings (NOB), Number of Redemptions (NOR), Gross Revenue (GR), Gross Bookings (GB), refunds, unique visitors, redemption rate, promo codes, and impressions broken down by traffic source. The query joins `deal_attribute_data_daily` with `deal_impressions_traffic_source` and aggregates by date. Only the replica (session) database connection is used — there is no `shouldUsePrimaryDb` option for this endpoint.

## Trigger

- **Type**: api-call
- **Source**: External consumer (Marketing analytics)
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (caller) | Sends `GET /getDealAttributeMetrics` with query parameters | External |
| `DealAttributeApiV2Resource` | Receives HTTP request, passes parameters to DAO, returns response | `continuumDealPerformanceApiV2_dealAttributeApiV2Resource` |
| `DealPerformanceDAO` | Constructs attribute query SQL, determines selected columns, executes query, maps results | `continuumDealPerformanceApiV2_dealPerformanceDao` |
| Deal Performance PostgreSQL | Executes the attribute query and returns daily aggregated rows | `continuumDealPerformancePostgres` |

## Steps

1. **Receives attribute metrics request**: Consumer sends `GET /getDealAttributeMetrics` with optional query parameters: `dealId` (UUID), `brand` (GROUPON or LIVINGSOCIAL), `attributes` (array of attribute names), `fromDate`, `toDate`.
   - From: Consumer
   - To: `continuumDealPerformanceApiV2_dealAttributeApiV2Resource`
   - Protocol: REST/HTTP

2. **Resolves selected columns**: The DAO maps each requested `AttributeName` enum value to its database column name. If `IMPRESSIONS` is requested, additional columns are added for all `ImpressionPosition` and `TrafficSource` enum values (i.e., impression breakdown columns are automatically included).
   - From: `continuumDealPerformanceApiV2_dealAttributeApiV2Resource`
   - To: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - Protocol: Direct (in-process)

3. **Constructs attribute SQL**: The DAO builds a dynamic SQL query of the form `SELECT date_value, sum(<col>) AS <col> FROM deal_attribute_data_daily LEFT JOIN deal_impressions_traffic_source ON id WHERE date_value BETWEEN :fromDate AND :toDate AND deal_id = :dealId [AND brand = :brand] GROUP BY date_value ORDER BY date_value DESC`. The column list is built at runtime from the resolved attribute set.
   - From: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - To: In-process SQL builder
   - Protocol: Direct

4. **Executes query against PostgreSQL**: The DAO binds parameters and executes the query via JDBI on the default (read-only replica) connection. Optionally binds `:brand` if a brand filter was supplied.
   - From: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - To: `continuumDealPerformancePostgres`
   - Protocol: JDBC/PostgreSQL

5. **Maps result rows**: Each result row is mapped to a `DealAttributeMetric` object with a `date` string and an `attributes` map of column name to aggregated double value.
   - From: `continuumDealPerformancePostgres`
   - To: `continuumDealPerformanceApiV2_dealPerformanceDao`
   - Protocol: JDBC result set

6. **Returns response**: The resource returns the list of `DealAttributeMetric` objects as HTTP 200 JSON.
   - From: `continuumDealPerformanceApiV2_dealAttributeApiV2Resource`
   - To: Consumer
   - Protocol: REST/HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid `dealId` UUID format | JAX-RS parameter binding fails | HTTP 4xx |
| Invalid `brand` or `attributes` enum value | JAX-RS enum deserialization fails | HTTP 4xx |
| Database query exception | JDBI propagates exception | HTTP 5xx |
| No rows found | Empty list returned | HTTP 200 with empty array |

## Sequence Diagram

```
Consumer -> DealAttributeApiV2Resource: GET /getDealAttributeMetrics?dealId=...&brand=...&attributes=...&fromDate=...&toDate=...
DealAttributeApiV2Resource -> DealPerformanceDAO: getDealAttributeMetrics(dealId, brand, attributes, fromDate, toDate)
DealPerformanceDAO -> DealPerformanceDAO: resolveSelectedColumns(attributes)
DealPerformanceDAO -> DealPerformanceDAO: buildAttributeSQL(selectedColumns, brand)
DealPerformanceDAO -> PostgreSQL: SELECT date_value, sum(col)... FROM deal_attribute_data_daily LEFT JOIN deal_impressions_traffic_source WHERE deal_id=:dealId AND date BETWEEN :fromDate AND :toDate [AND brand=:brand] GROUP BY date_value ORDER BY date_value DESC
PostgreSQL --> DealPerformanceDAO: daily attribute rows
DealPerformanceDAO -> DealPerformanceDAO: map to List<DealAttributeMetric>
DealPerformanceDAO --> DealAttributeApiV2Resource: List<DealAttributeMetric>
DealAttributeApiV2Resource --> Consumer: HTTP 200 List<DealAttributeMetric> (JSON)
```

## Related

- Architecture dynamic view: `dynamic-deal-performance-query-flow`
- Related flows: [Deal Performance Metrics Query](deal-performance-metrics-query.md), [Deal Option Performance Metrics Query](deal-option-performance-metrics-query.md)
