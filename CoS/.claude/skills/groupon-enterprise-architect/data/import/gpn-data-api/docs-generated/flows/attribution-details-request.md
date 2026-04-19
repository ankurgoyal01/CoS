---
service: "gpn-data-api"
title: "Attribution Details Request"
generated: "2026-03-03"
type: flow
flow_name: "attribution-details-request"
flow_type: synchronous
trigger: "HTTP POST /attribution/orders from an upstream consumer (e.g., sem-ui)"
participants:
  - "attributionApiClients_unk_2f3c"
  - "continuumGpnDataApiService"
  - "attributionDetailsResource"
  - "attributionDetailsService"
  - "attributionQueryCountDao"
  - "continuumGpnDataApiMySql"
  - "gpnDataApi_bigQueryService"
  - "bigQuery_unk_a1b2"
architecture_ref: "dynamic-attributionDetailsFlow"
---

# Attribution Details Request

## Summary

An upstream consumer (such as `sem-ui`) submits a list of order identifiers and a date range. The service validates the request, checks and increments the per-day query count against MySQL, splits the order IDs into batches of up to 1,000, executes parameterised BigQuery queries for each batch, and returns all matching attribution records as a JSON array.

## Trigger

- **Type**: api-call
- **Source**: `sem-ui` (Attribution Lens) or any other HTTP client calling `POST /attribution/orders`
- **Frequency**: On demand (per attribution lookup request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream consumer (e.g., sem-ui) | Initiates the attribution lookup | `attributionApiClients_unk_2f3c` |
| Attribution Details Resource | Receives and validates the HTTP request; routes to service; serialises the response | `attributionDetailsResource` |
| Attribution Details Service | Orchestrates limit checking, batching, BigQuery dispatch, and result mapping | `attributionDetailsService` |
| Attribution Query Count DAO | Reads the daily limit and updates today's query count in MySQL | `attributionQueryCountDao` |
| GPN Data API MySQL | Stores `attribution_properties` (limit config) and `attribution_query_count` (daily usage) | `continuumGpnDataApiMySql` |
| BigQuery Service | Constructs and executes parameterised SQL against BigQuery | `gpnDataApi_bigQueryService` |
| Google BigQuery (`prj-grp-dataview-prod-1ff9`) | Executes the query and returns `TableResult` | `bigQuery_unk_a1b2` |

## Steps

1. **Receives attribution request**: Upstream consumer sends `POST /attribution/orders` with `orderIdType`, `orderIds`, `fromDate`, and `toDate` in the JSON body.
   - From: upstream consumer
   - To: `attributionDetailsResource`
   - Protocol: HTTPS/JSON

2. **Validates and dispatches**: `attributionDetailsResource` validates request fields (not-null constraints) and invokes `attributionDetailsService.getAttributionDetails()`.
   - From: `attributionDetailsResource`
   - To: `attributionDetailsService`
   - Protocol: direct (in-process)

3. **Reads daily query limit**: `attributionDetailsService` calls `attributionQueryCountDao.getMaximumQueryPerDay()`, which selects `property_value` from `attribution_properties` where `property_name = 'attribution_teradata'`.
   - From: `attributionDetailsService`
   - To: `attributionQueryCountDao` → `continuumGpnDataApiMySql`
   - Protocol: JDBC

4. **Increments daily query count**: `attributionQueryCountDao.updateQueryCount(today)` upserts a row in `attribution_query_count`, incrementing the count for the current calendar date.
   - From: `attributionDetailsService`
   - To: `attributionQueryCountDao` → `continuumGpnDataApiMySql`
   - Protocol: JDBC

5. **Checks limit**: `attributionDetailsService` reads the updated count via `getCurrentDayQueryCount(today)` and compares it to the max. If exceeded, throws `MaximumQueryLimitReachedException`.
   - From: `attributionDetailsService`
   - To: `attributionQueryCountDao` → `continuumGpnDataApiMySql`
   - Protocol: JDBC

6. **Batches order IDs**: For lists exceeding 1,000 IDs, `attributionDetailsService` splits `orderIds` into sublists of at most 1,000 items. For `SUPPORT_ID` type, dashes are stripped from IDs before querying.
   - From: `attributionDetailsService`
   - To: `attributionDetailsService` (internal)
   - Protocol: in-process

7. **Executes BigQuery queries**: For each batch, `attributionDetailsService` invokes the appropriate `BigQueryService` method based on `orderIdType`:
   - `LEGACY_ID` → `getAttributionDetailsByLegacyId()` — filters by `oa.order_id IN UNNEST(@orderIds)`
   - `SUPPORT_ID` → `getAttributionDetailsBySupportId()` — filters by `po.support_id_original IN UNNEST(@supportIds)`
   - `PROMO_CODE` → `getAttributionDetailsByPromoCode()` — filters by `ue.incentive_promo_code IN UNNEST(@promoCodes)`
   - From: `attributionDetailsService`
   - To: `gpnDataApi_bigQueryService` → BigQuery (`prj-grp-dataview-prod-1ff9`)
   - Protocol: BigQuery API (Google Cloud SDK)

8. **Maps results to DTOs**: Each `TableResult` row is mapped to an `AttributionDetailsDto`. Rows with a null `order_id` are filtered out. The `utm_campaign` field is parsed into `pid`, `cid`, and `pub` sub-fields.
   - From: `attributionDetailsService`
   - To: `attributionDetailsResource`
   - Protocol: in-process

9. **Returns JSON response**: `attributionDetailsResource` serialises the list of `AttributionDetailsDto` objects as `application/json` with HTTP 200.
   - From: `attributionDetailsResource`
   - To: upstream consumer
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Daily query limit exceeded | Throws `MaximumQueryLimitReachedException`; caught in the resource | HTTP 429 with message text |
| Empty `orderIds` list | Returns empty list immediately without querying BigQuery | HTTP 200 with `[]` |
| BigQuery query interrupted | Re-interrupts the thread; throws `AttributionServiceException` | HTTP 500 |
| BigQuery API error | Catches `BigQueryException`; throws `AttributionServiceException` | HTTP 500 |
| Invalid `orderIdType` | Throws `AttributionServiceException` with "Unsupported order ID type" | HTTP 500 |

## Sequence Diagram

```
sem-ui -> attributionDetailsResource: POST /attribution/orders {orderIdType, orderIds, fromDate, toDate}
attributionDetailsResource -> attributionDetailsService: getAttributionDetails(orderIdType, orderIds, fromDate, toDate)
attributionDetailsService -> attributionQueryCountDao: getMaximumQueryPerDay()
attributionQueryCountDao -> continuumGpnDataApiMySql: SELECT property_value FROM attribution_properties WHERE property_name = 'attribution_teradata'
continuumGpnDataApiMySql --> attributionQueryCountDao: maxLimit
attributionQueryCountDao -> continuumGpnDataApiMySql: INSERT/UPDATE attribution_query_count
attributionDetailsService -> attributionQueryCountDao: getCurrentDayQueryCount(today)
continuumGpnDataApiMySql --> attributionDetailsService: currentCount
attributionDetailsService -> gpnDataApi_bigQueryService: getAttributionDetailsBy<Type>(batch, fromDate, toDate) [per batch]
gpnDataApi_bigQueryService -> BigQuery: parameterized SQL query (prj-grp-dataview-prod-1ff9)
BigQuery --> gpnDataApi_bigQueryService: TableResult
gpnDataApi_bigQueryService --> attributionDetailsService: TableResult
attributionDetailsService --> attributionDetailsResource: List<AttributionDetailsDto>
attributionDetailsResource --> sem-ui: HTTP 200 application/json [attribution records]
```

## Related

- Architecture dynamic view: `dynamic-attributionDetailsFlow`
- Related flows: [Paginated Attribution Request](attribution-details-paginated.md), [Attribution CSV Export](attribution-csv-export.md)
