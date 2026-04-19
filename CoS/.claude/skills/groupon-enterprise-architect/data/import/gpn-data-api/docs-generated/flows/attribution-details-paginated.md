---
service: "gpn-data-api"
title: "Paginated Attribution Request"
generated: "2026-03-03"
type: flow
flow_name: "attribution-details-paginated"
flow_type: synchronous
trigger: "HTTP POST /attribution/orders/paginated from an upstream consumer"
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

# Paginated Attribution Request

## Summary

A caller requests attribution data in pages via `POST /attribution/orders/paginated`. On the first call, the service runs a BigQuery query and returns the first page together with a `jobId` and `nextPageToken`. On subsequent calls, the caller supplies both tokens and the service reuses the existing BigQuery job to fetch the next page without re-executing the query. The daily query count is incremented on every call (including page iterations).

## Trigger

- **Type**: api-call
- **Source**: `sem-ui` (Attribution Lens) or any HTTP client that needs to page through large result sets
- **Frequency**: On demand; typically multiple sequential calls per attribution session (one per page)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream consumer (e.g., sem-ui) | Initiates and drives pagination | `attributionApiClients_unk_2f3c` |
| Attribution Details Resource | Receives request, extracts pagination parameters, serialises paginated response | `attributionDetailsResource` |
| Attribution Details Service | Enforces limit, selects BigQuery method, constructs `PaginatedResponseDto` | `attributionDetailsService` |
| Attribution Query Count DAO | Reads limit and increments daily count | `attributionQueryCountDao` |
| GPN Data API MySQL | Persists daily query count and max limit configuration | `continuumGpnDataApiMySql` |
| BigQuery Service | Creates or reuses a BigQuery job; retrieves a single page of results | `gpnDataApi_bigQueryService` |
| Google BigQuery (`prj-grp-dataview-prod-1ff9`) | Executes and caches the query job for page iteration | `bigQuery_unk_a1b2` |

## Steps

1. **Receives paginated request**: Caller sends `POST /attribution/orders/paginated` with `orderIdType`, `orderIds`, `fromDate`, `toDate`, and optionally `pagination.pageSize`, `pagination.pageToken`, and `pagination.jobId`.
   - From: upstream consumer
   - To: `attributionDetailsResource`
   - Protocol: HTTPS/JSON

2. **Validates and dispatches**: `attributionDetailsResource` validates not-null fields and calls `attributionDetailsService.getAttributionDetailsPaginated()`.
   - From: `attributionDetailsResource`
   - To: `attributionDetailsService`
   - Protocol: direct (in-process)

3. **Determines effective page size**: If `pagination.pageSize` is absent, defaults to 100 rows. Maximum allowed is 1,000 (enforced by Swagger schema constraint).
   - From: `attributionDetailsService` (internal)

4. **Checks and increments daily limit**: Same limit check and count increment as the non-paginated flow (steps 3–5 of the Attribution Details Request flow).
   - From: `attributionDetailsService`
   - To: `attributionQueryCountDao` → `continuumGpnDataApiMySql`
   - Protocol: JDBC

5. **Determines BigQuery execution path**:
   - If `pagination.jobId` is absent: creates a new BigQuery job (`bigQuery.create(JobInfo...)`) using the parameterised SQL for the given `orderIdType`. The query is ordered by `oa.order_id`, `po.support_id_original`, or `ue.incentive_promo_code` to enable stable pagination.
   - If `pagination.jobId` is present: retrieves the existing job via `bigQuery.getJob(JobId.of(jobId))` to avoid re-executing the query.
   - From: `attributionDetailsService`
   - To: `gpnDataApi_bigQueryService`
   - Protocol: in-process

6. **Waits for job completion**: Calls `queryJob.waitFor()` to block until the BigQuery job finishes (applies to new jobs only; existing jobs are already complete).
   - From: `gpnDataApi_bigQueryService`
   - To: BigQuery
   - Protocol: BigQuery API

7. **Fetches the requested page**: Calls `queryJob.getQueryResults(options)` with `pageSize` and optionally `pageToken` to retrieve the specific page.
   - From: `gpnDataApi_bigQueryService`
   - To: BigQuery
   - Protocol: BigQuery API

8. **Returns `PaginatedTableResult`**: Wraps `TableResult` with `nextPageToken`, `totalRows`, and `hasNextPage` from the BigQuery response.
   - From: `gpnDataApi_bigQueryService`
   - To: `attributionDetailsService`
   - Protocol: in-process

9. **Maps rows to DTOs and builds response**: Maps each `FieldValueList` row to `AttributionDetailsDto`; constructs `PaginatedResponseDto` with `data`, `nextPageToken`, `totalCount`, `hasNextPage`, and `pageSize`.
   - From: `attributionDetailsService`
   - To: `attributionDetailsResource`
   - Protocol: in-process

10. **Returns JSON response**: `attributionDetailsResource` serialises the `PaginatedResponseDto` as `application/json` with HTTP 200.
    - From: `attributionDetailsResource`
    - To: upstream consumer
    - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Daily query limit exceeded | Throws `MaximumQueryLimitReachedException`; caught in resource | HTTP 429 |
| Empty `orderIds` list | Returns empty `PaginatedResponseDto` immediately | HTTP 200 with empty data and `totalCount: 0` |
| `jobId` supplied but job not found in BigQuery | Throws `AttributionServiceException("Job with ID ... not found")` | HTTP 500 |
| BigQuery interrupted | Re-interrupts thread; throws `AttributionServiceException` | HTTP 500 |
| BigQuery API error | Catches `BigQueryException`; throws `AttributionServiceException` | HTTP 500 |

## Sequence Diagram

```
sem-ui -> attributionDetailsResource: POST /attribution/orders/paginated {orderIdType, orderIds, fromDate, toDate, pagination}
attributionDetailsResource -> attributionDetailsService: getAttributionDetailsPaginated(...)
attributionDetailsService -> attributionQueryCountDao: getMaximumQueryPerDay() + updateQueryCount() + getCurrentDayQueryCount()
attributionQueryCountDao -> continuumGpnDataApiMySql: [SQL limit + count operations]
continuumGpnDataApiMySql --> attributionDetailsService: limit OK
attributionDetailsService -> gpnDataApi_bigQueryService: getAttributionDetailsBy<Type>Paginated(orderIds, pageToken, pageSize, fromDate, toDate, jobId)
gpnDataApi_bigQueryService -> BigQuery: create new job OR retrieve existing job
BigQuery --> gpnDataApi_bigQueryService: job handle
gpnDataApi_bigQueryService -> BigQuery: queryJob.getQueryResults(pageSize, pageToken)
BigQuery --> gpnDataApi_bigQueryService: TableResult (page N)
gpnDataApi_bigQueryService --> attributionDetailsService: PaginatedTableResult {result, nextPageToken, totalRows, hasNextPage}
attributionDetailsService --> attributionDetailsResource: PaginatedResponseDto<AttributionDetailsDto>
attributionDetailsResource --> sem-ui: HTTP 200 {data, nextPageToken, totalCount, hasNextPage, pageSize}
```

## Related

- Architecture dynamic view: `dynamic-attributionDetailsFlow`
- Related flows: [Attribution Details Request](attribution-details-request.md), [Attribution CSV Export](attribution-csv-export.md)
