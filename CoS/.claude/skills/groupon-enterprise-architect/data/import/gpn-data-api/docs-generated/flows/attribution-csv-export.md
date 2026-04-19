---
service: "gpn-data-api"
title: "Attribution CSV Export"
generated: "2026-03-03"
type: flow
flow_name: "attribution-csv-export"
flow_type: synchronous
trigger: "HTTP POST /attribution/orders/csv from an upstream consumer"
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

# Attribution CSV Export

## Summary

A caller requests the full set of attribution records for a given set of order identifiers and date range, delivered as a downloadable CSV file. The flow follows the same query path as the JSON endpoint — enforcing the daily limit, batching BigQuery queries, and mapping results — but the final serialisation step produces `text/csv` output using Jackson CSV, with each attribution record flattened to a key-value row.

## Trigger

- **Type**: api-call
- **Source**: `sem-ui` (Attribution Lens download button) or a direct API client
- **Frequency**: On demand (typically lower frequency than JSON lookups; used for bulk exports)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream consumer (e.g., sem-ui) | Initiates the CSV download | `attributionApiClients_unk_2f3c` |
| Attribution Details Resource | Receives request; delegates to service; returns `text/csv` response | `attributionDetailsResource` |
| Attribution Details Service | Calls `getAttributionDetailsCsv()`, which internally calls `getAttributionDetails()` and converts DTOs to `Map<String, String>` rows | `attributionDetailsService` |
| Attribution Query Count DAO | Reads limit and increments daily count | `attributionQueryCountDao` |
| GPN Data API MySQL | Persists daily query count and limit config | `continuumGpnDataApiMySql` |
| BigQuery Service | Executes parameterised BigQuery queries | `gpnDataApi_bigQueryService` |
| Google BigQuery (`prj-grp-dataview-prod-1ff9`) | Returns attribution data | `bigQuery_unk_a1b2` |

## Steps

1. **Receives CSV export request**: Caller sends `POST /attribution/orders/csv` with `orderIdType`, `orderIds`, `fromDate`, and `toDate` in the JSON body.
   - From: upstream consumer
   - To: `attributionDetailsResource`
   - Protocol: HTTPS/JSON (request body); response in `text/csv`

2. **Delegates to CSV service method**: `attributionDetailsResource.getAttributionDetailsCsv()` calls `attributionDetailsService.getAttributionDetailsCsv()`.
   - From: `attributionDetailsResource`
   - To: `attributionDetailsService`
   - Protocol: direct (in-process)

3. **Executes core attribution lookup**: `getAttributionDetailsCsv()` internally calls `getAttributionDetails()` — the same limit check, count increment, batching, and BigQuery query execution path as the JSON endpoint. See [Attribution Details Request](attribution-details-request.md) steps 3–8 for the full sub-flow.
   - From: `attributionDetailsService`
   - To: `attributionQueryCountDao`, `gpnDataApi_bigQueryService`
   - Protocol: JDBC / BigQuery API

4. **Converts DTOs to flat maps**: Each `AttributionDetailsDto` is converted to a `Map<String, String>` using `convertDtoToMap()`. All 22 fields are included as string key-value pairs: `orderId`, `supportId`, `attrDatetime`, `countryCode`, `utmMedium`, `utmSource`, `utmCampaign`, `dealUuid`, `platform`, `unitPrice`, `quantity`, `paymentAmount`, `gBucks`, `action`, `transactionDateTs`, `pid`, `cid`, `pub`, `incentivePromoCode`, `trafficSource`, `trafficSubSource`, `fullUrl`.
   - From: `attributionDetailsService` (internal)

5. **Returns `List<Map<String, String>>`**: The list of flat maps is returned to `attributionDetailsResource`.
   - From: `attributionDetailsService`
   - To: `attributionDetailsResource`
   - Protocol: in-process

6. **Serialises as CSV**: Dropwizard and Jackson CSV (`jackson-dataformat-csv`) serialise the list of maps to `text/csv`. Each map becomes one CSV row; keys become column headers.
   - From: `attributionDetailsResource`
   - To: upstream consumer
   - Protocol: HTTPS (`Content-Type: text/csv`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Daily query limit exceeded | Throws `MaximumQueryLimitReachedException` — propagated as `AttributionServiceException` (not caught at CSV layer) | HTTP 500 (differs from JSON endpoint which returns HTTP 429 — the CSV handler does not catch `MaximumQueryLimitReachedException`) |
| Empty `orderIds` list | Returns empty list; serialises as an empty CSV with headers only | HTTP 200 with empty CSV |
| BigQuery error | Throws `AttributionServiceException`; propagated to Dropwizard exception handler | HTTP 500 |

## Sequence Diagram

```
sem-ui -> attributionDetailsResource: POST /attribution/orders/csv {orderIdType, orderIds, fromDate, toDate}
attributionDetailsResource -> attributionDetailsService: getAttributionDetailsCsv(orderIdType, orderIds, fromDate, toDate)
attributionDetailsService -> attributionDetailsService: getAttributionDetails(...) [full BigQuery + limit check sub-flow]
attributionDetailsService -> attributionQueryCountDao: limit check + count update
attributionQueryCountDao -> continuumGpnDataApiMySql: [SQL operations]
attributionDetailsService -> gpnDataApi_bigQueryService: getAttributionDetailsBy<Type>(batch, fromDate, toDate) [per batch]
gpnDataApi_bigQueryService -> BigQuery: parameterized SQL (prj-grp-dataview-prod-1ff9)
BigQuery --> gpnDataApi_bigQueryService: TableResult
attributionDetailsService -> attributionDetailsService: convertDtoToMap() for each row
attributionDetailsService --> attributionDetailsResource: List<Map<String, String>>
attributionDetailsResource --> sem-ui: HTTP 200 text/csv [flattened attribution rows]
```

## Related

- Architecture dynamic view: `dynamic-attributionDetailsFlow`
- Related flows: [Attribution Details Request](attribution-details-request.md), [Paginated Attribution Request](attribution-details-paginated.md)
