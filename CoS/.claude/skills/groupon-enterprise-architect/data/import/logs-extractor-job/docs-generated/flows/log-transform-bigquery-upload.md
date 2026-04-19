---
service: "logs-extractor-job"
title: "Log Transformation and BigQuery Upload"
generated: "2026-03-03"
type: flow
flow_name: "log-transform-bigquery-upload"
flow_type: batch
trigger: "Called by CLI Job Runner after log extraction when ENABLE_BIGQUERY=true and a log array is non-empty"
participants:
  - "continuumLogExtractorJob_cliRunner"
  - "continuumLogExtractorJob_bigQueryService"
  - "continuumLogExtractorBigQuery"
architecture_ref: "dynamic-hourly-log-extraction"
---

# Log Transformation and BigQuery Upload

## Summary

For each non-empty log type returned by extraction, the BigQuery Service applies a type-specific transformation that maps raw Elasticsearch field names to the BigQuery schema, sanitizes `undefined` to `null`, and serializes nested objects to JSON strings. It then appends an `extraction_timestamp` to every row and uploads the rows to BigQuery in batches of 500 using `table.insert()` with `skipInvalidRows: true`. This flow runs for each of the six target tables: `pwa_logs`, `proxy_logs`, `lazlo_logs`, `orders_logs`, `bcookie_summary`, and `combined_logs`.

## Trigger

- **Type**: batch (in-process function call)
- **Source**: `continuumLogExtractorJob_cliRunner` calls `bigQueryService.uploadLogs(tableName, rows)` for each log type
- **Frequency**: Up to 6 times per job run (once per non-empty log type), when `ENABLE_BIGQUERY=true`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLI Job Runner | Checks array length; calls transform then upload for each log type | `continuumLogExtractorJob_cliRunner` |
| BigQuery Service | Applies transformation; batches and inserts rows | `continuumLogExtractorJob_bigQueryService` |
| BigQuery Dataset | Receives batched row inserts | `continuumLogExtractorBigQuery` |

## Steps

1. **Check log array length**: CLI Job Runner checks `extractedLogs.{type}.length > 0` before calling the transform and upload pair.
   - From: `continuumLogExtractorJob_cliRunner`
   - To: (in-memory)
   - Protocol: in-process

2. **Transform log records**: BigQuery Service applies the type-specific transform method:
   - `transformPWALogs(pwa_logs)` — maps `@timestamp`, `bcookie`, `ccookie`, `cat`, `name`, `platform`, `errorCode`, `isGuest`, `paymentMethod`, `cartData` (JSON), `data` (JSON)
   - `transformProxyLogs(proxy_logs)` — maps `timestamp`, `requestId`, `bcookie`, `status`, `route`, `path`, `method`, `errorMessage`
   - `transformLazloLogs(lazlo_logs)` — maps `timestamp`, `requestId`, `path`, `statusCode`, `name`, `legacyMethod`, `action`, `clientName`
   - `transformOrdersLogs(orders_logs)` — maps `timestamp`, `bcookie`, `requestId`, `statusCode`, `endpoint`, `errorCodes[]`, `errorMessagesArray[]`
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

3. **Append extraction timestamp**: Every row receives `extraction_timestamp: new Date()` (the wall-clock time of upload, not extraction).
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

4. **Split into batches of 500**: The full array is sliced into chunks of 500 rows.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

5. **Insert each batch**: Calls `table.insert(batch, { skipInvalidRows: true, ignoreUnknownValues: true })` for each chunk.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: `continuumLogExtractorBigQuery`
   - Protocol: BigQuery API (HTTPS)

6. **Handle PartialFailureError**: If BigQuery returns a `PartialFailureError`, the failed row errors are logged at `warn` level and the batch loop continues. Other errors rethrow.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: `continuumLogExtractorJob_logging`
   - Protocol: in-process

7. **Log success**: Total uploaded row count logged at `success` level.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: `continuumLogExtractorJob_logging`
   - Protocol: in-process

## Transformation Field Mappings

| Log Type | Source Field | BigQuery Field | Notes |
|----------|-------------|----------------|-------|
| pwa_logs | `@timestamp` or `timestamp` | `timestamp` | REQUIRED |
| pwa_logs | `bcookie` or `data.cookies.b` | `bcookie` | |
| pwa_logs | `data` (object) | `data` | Serialized to JSON string |
| proxy_logs | `@timestamp` or `timestamp` | `timestamp` | REQUIRED |
| proxy_logs | `status` | `status` | INTEGER |
| lazlo_logs | `data.requestId` or `requestId` | `requestId` | |
| lazlo_logs | `data.status` or `statusCode` | `statusCode` | Coerced to STRING |
| orders_logs | `b_cookie` or `bcookie` | `bcookie` | |
| orders_logs | `http_request_id` or `requestId` | `requestId` | |
| orders_logs | `error_codes` or `errorCodes` | `errorCodes` | REPEATED STRING |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Empty log array | Skipped (upload not called) | No-op; job continues |
| `PartialFailureError` | Failed rows logged at warn; batch loop continues | Partial data; job exits 0 |
| Other BigQuery insert error | Caught; rethrown from `uploadLogs`; caught in `main()` | Job exits with code 1 |

## Sequence Diagram

```
CLIRunner -> BigQueryService: transformPWALogs(pwa_logs)
BigQueryService --> CLIRunner: transformedRows[]
CLIRunner -> BigQueryService: uploadLogs('pwa_logs', transformedRows)
loop for each batch of 500
  BigQueryService -> BigQuery: table.insert(batch, {skipInvalidRows: true})
  alt PartialFailureError
    BigQueryService -> Logger: warn(failedRows)
  end
end
BigQueryService --> CLIRunner: success
CLIRunner -> BigQueryService: transformProxyLogs / uploadLogs (repeat for each type)
```

## Related

- Architecture dynamic view: `dynamic-hourly-log-extraction`
- Related flows: [Hourly Log Extraction and Load](hourly-log-extraction.md), [BigQuery Table Initialization](bigquery-table-init.md), [Combined Logs Denormalization](combined-logs-denormalization.md)
