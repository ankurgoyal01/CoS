---
service: "logs-extractor-job"
title: "Combined Logs Denormalization"
generated: "2026-03-03"
type: flow
flow_name: "combined-logs-denormalization"
flow_type: batch
trigger: "Called when pwa_logs array is non-empty, after per-type uploads complete"
participants:
  - "continuumLogExtractorJob_cliRunner"
  - "continuumLogExtractorJob_bigQueryService"
  - "continuumLogExtractorJob_mySQLService"
  - "continuumLogExtractorBigQuery"
  - "continuumLogExtractorMySQL"
architecture_ref: "dynamic-hourly-log-extraction"
---

# Combined Logs Denormalization

## Summary

After per-type log uploads are complete, the job produces a `combined_logs` table by denormalizing PWA logs as the primary record type and joining related proxy, Lazlo, and orders logs by `requestId`. For each PWA log, the job looks up matching proxy, Lazlo, and orders records in in-memory hash maps. If no related logs exist for a PWA event, the row is inserted with null values for all non-PWA fields. If multiple related logs share the same `requestId`, one combined row is produced per related log entry (fan-out up to `max(proxyCount, lazloCount, ordersCount)` rows per PWA event). The resulting records are uploaded to `combined_logs` in BigQuery and/or MySQL using the same batch-insert approach as other log types.

## Trigger

- **Type**: batch (in-process function call)
- **Source**: `continuumLogExtractorJob_cliRunner` calls `transformCombinedLogsDenormalized(extractedLogs)` when `pwa_logs.length > 0`
- **Frequency**: Once per job run per sink (BigQuery and/or MySQL)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLI Job Runner | Guards on non-empty PWA logs; invokes denormalization and upload | `continuumLogExtractorJob_cliRunner` |
| BigQuery Service | Performs denormalization; produces combined row objects for BigQuery | `continuumLogExtractorJob_bigQueryService` |
| MySQL Service | Performs its own denormalization variant; produces combined row arrays for MySQL | `continuumLogExtractorJob_mySQLService` |
| BigQuery Dataset | Receives `combined_logs` rows | `continuumLogExtractorBigQuery` |
| MySQL Database | Receives `combined_logs` rows | `continuumLogExtractorMySQL` |

## Steps

1. **Build lookup maps**: Iterates `proxy_logs`, `lazlo_logs`, and `orders_logs` arrays to build three `Map<requestId, log[]>` structures for O(1) joins.
   - From: `continuumLogExtractorJob_bigQueryService` or `continuumLogExtractorJob_mySQLService`
   - To: (in-memory)
   - Protocol: in-process

2. **Iterate PWA logs**: For each PWA log record, resolves related log arrays via `requestId` lookup.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

3. **Single-record case**: If no related proxy, Lazlo, or orders logs exist for a PWA requestId, emits one combined row with all non-PWA fields set to `null`.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

4. **Fan-out case**: If related logs exist, calculates `maxRelatedLogs = max(proxy.length, lazlo.length, orders.length)` and emits that many combined rows. Each row carries the PWA log fields plus the indexed proxy, Lazlo, or orders log at position `i` (or null if that index exceeds the array length for that type).
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

5. **Upload combined_logs**: Calls `bigQueryService.uploadLogs('combined_logs', denormalizedRows)` or `mysqlService.uploadLogs('combined_logs', denormalizedRows)` with the resulting array.
   - From: `continuumLogExtractorJob_cliRunner`
   - To: `continuumLogExtractorBigQuery` / `continuumLogExtractorMySQL`
   - Protocol: BigQuery API / MySQL protocol

## Combined Logs Schema Fields

| Field Group | Fields |
|-------------|--------|
| Common | `timestamp`, `requestId`, `bcookie`, `ccookie`, `path`, `error_message`, `extraction_timestamp` |
| PWA | `message`, `cat`, `name`, `platform`, `errorCode`, `isGuest`, `userAgent`, `ipAddress`, `paymentMethod`, `customerMessage`, `cartData`, `data` |
| Proxy (prefixed `proxy_`) | `proxy_status`, `proxy_route`, `proxy_method`, `proxy_error_message` |
| Lazlo (prefixed `lazlo_`) | `lazlo_status_code`, `lazlo_name`, `lazlo_legacy_method`, `lazlo_action`, `lazlo_client_name` |
| Orders (prefixed `orders_`) | `orders_status_code`, `orders_endpoint`, `orders_error_codes`, `orders_error_messages_array` |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Empty pwa_logs array | Guard check; `transformCombinedLogsDenormalized` returns `[]`; upload is skipped | No-op; job continues |
| PWA log has no requestId | Related maps return empty arrays; single-record (null-filled) row emitted | Row still written; non-PWA fields are null |
| Combined rows array is empty after transform | `uploadLogs` guard checks `logs.length === 0`; skips insert | No-op |

## Sequence Diagram

```
CLIRunner -> BigQueryService: transformCombinedLogsDenormalized({pwa_logs, proxy_logs, lazlo_logs, orders_logs})
BigQueryService -> BigQueryService: Build requestId -> [log] maps for proxy, lazlo, orders
loop for each pwaLog
  BigQueryService -> BigQueryService: Lookup proxy/lazlo/orders by requestId
  alt no related logs
    BigQueryService -> BigQueryService: Emit 1 row (null non-PWA fields)
  else related logs present
    loop i = 0 to max(proxy.len, lazlo.len, orders.len)
      BigQueryService -> BigQueryService: Emit 1 combined row
    end
  end
end
BigQueryService --> CLIRunner: denormalizedCombinedLogs[]
CLIRunner -> BigQueryService: uploadLogs('combined_logs', denormalizedCombinedLogs)
BigQueryService -> BigQuery: table.insert(batch of 500)
```

## Related

- Architecture dynamic view: `dynamic-hourly-log-extraction`
- Related flows: [Hourly Log Extraction and Load](hourly-log-extraction.md), [Log Transformation and BigQuery Upload](log-transform-bigquery-upload.md), [BCookie Session Summary Generation](bcookie-summary-generation.md)
