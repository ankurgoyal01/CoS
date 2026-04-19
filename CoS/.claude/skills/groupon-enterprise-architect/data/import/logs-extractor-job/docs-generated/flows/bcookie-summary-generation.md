---
service: "logs-extractor-job"
title: "BCookie Session Summary Generation"
generated: "2026-03-03"
type: flow
flow_name: "bcookie-summary-generation"
flow_type: batch
trigger: "Called when pwa_logs array is non-empty, during BigQuery and/or MySQL upload phase"
participants:
  - "continuumLogExtractorJob_cliRunner"
  - "continuumLogExtractorJob_bigQueryService"
  - "continuumLogExtractorBigQuery"
  - "continuumLogExtractorMySQL"
architecture_ref: "dynamic-hourly-log-extraction"
---

# BCookie Session Summary Generation

## Summary

The BCookie Session Summary flow aggregates per-browser-cookie (`bcookie`) behavioral statistics from the `pwa_logs` extract. For each unique `bcookie` value, it accumulates the set of distinct event names, the set of distinct session identifiers (macaroon cookies or transaction IDs), the first and last seen timestamps, and boolean flags indicating whether the cookie was associated with a completed purchase or an API error event. The resulting summary rows are uploaded to the `bcookie_summary` table in BigQuery and/or MySQL, enabling downstream analysis of user journeys and conversion funnels within an hour.

## Trigger

- **Type**: batch (in-process function call)
- **Source**: `continuumLogExtractorJob_cliRunner` calls `bigQueryService.generateBCookieSummary(pwa_logs)` when `pwa_logs.length > 0`
- **Frequency**: Once per job run per sink, when PWA logs are present

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLI Job Runner | Guards on non-empty PWA logs; calls generation then upload | `continuumLogExtractorJob_cliRunner` |
| BigQuery Service | Generates the bcookie summary records from PWA logs | `continuumLogExtractorJob_bigQueryService` |
| BigQuery Dataset | Receives `bcookie_summary` rows | `continuumLogExtractorBigQuery` |
| MySQL Database | Receives `bcookie_summary` rows (if MySQL enabled) | `continuumLogExtractorMySQL` |

## Steps

1. **Guard check**: CLI Job Runner checks `pwa_logs.length > 0` before calling `generateBCookieSummary`.
   - From: `continuumLogExtractorJob_cliRunner`
   - To: (in-memory)
   - Protocol: in-process

2. **Extract bCookie from each PWA log**: For each log, reads `log.bcookie` or `log.data.cookies.b`; records with value `'unknown'` are skipped.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

3. **Initialize or update bCookie record**: If the bCookie is new, creates an accumulator with empty `events` Set, `sessions` Set, `timestamps` array, and `hasPurchase`/`hasApiError` booleans. Updates the accumulator with the event name, session ID, and timestamp from the current log.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory `Map<bcookie, record>`)
   - Protocol: in-process

4. **Classify event name**: Reads event name from `log.data.message`, `log.data.name`, `log.data.cat`, `log.name`, `log.message`, or `log.cat` (in priority order). Adds to the `events` Set.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

5. **Detect purchase events**: Sets `hasPurchase = true` if the event name includes `'CHECKOUT-FINISHED'`, or matches `'PAYMENT' + 'SUCCESS'`, or matches `'ORDER' + 'COMPLETE'`.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

6. **Detect API error events**: Sets `hasApiError = true` if the event name includes both `'API-'` and `'ERROR'`.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

7. **Extract session ID**: Reads session from `log.data.cookies.macaroon`, `log.data.context.transactionId`, `log.macaroon`, `log.transactionId`, or `log.request_id`. Adds to the `sessions` Set if non-null.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

8. **Serialize summary records**: Converts the `Map` to an array. For each entry, sorts timestamps ascending and computes `firstSeen` / `lastSeen`. Outputs: `{ bcookie, eventCount, sessionCount, firstSeen, lastSeen, hasPurchase, hasApiError }`.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (in-memory)
   - Protocol: in-process

9. **Upload bcookie_summary**: Calls `uploadLogs('bcookie_summary', summaryArray)` to BigQuery and/or MySQL.
   - From: `continuumLogExtractorJob_cliRunner`
   - To: `continuumLogExtractorBigQuery` / `continuumLogExtractorMySQL`
   - Protocol: BigQuery API / MySQL protocol

## BCookie Summary Schema

| Field | Type | Description |
|-------|------|-------------|
| `bcookie` | STRING (REQUIRED) | Browser cookie identifier |
| `eventCount` | INTEGER | Number of distinct event names observed |
| `sessionCount` | INTEGER | Number of distinct session identifiers observed |
| `firstSeen` | TIMESTAMP | Earliest log timestamp for this bCookie in the hour |
| `lastSeen` | TIMESTAMP | Latest log timestamp for this bCookie in the hour |
| `hasPurchase` | BOOLEAN | True if any purchase completion event was observed |
| `hasApiError` | BOOLEAN | True if any API error event was observed |
| `extraction_timestamp` | TIMESTAMP (REQUIRED) | Wall-clock time of upload |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| All PWA logs have `bcookie = 'unknown'` | Records skipped; `summaryArray` is empty; upload skipped | No rows written to `bcookie_summary` |
| Empty `pwa_logs` array | Guard check; `generateBCookieSummary` not called | No-op |
| Upload error | Rethrown from `uploadLogs`; caught in `main()` | Job exits with code 1 |

## Sequence Diagram

```
CLIRunner -> BigQueryService: generateBCookieSummary(pwa_logs)
loop for each pwaLog
  BigQueryService -> BigQueryService: Extract bcookie (skip if 'unknown')
  BigQueryService -> BigQueryService: Accumulate events, sessions, timestamps in Map
  BigQueryService -> BigQueryService: Set hasPurchase / hasApiError flags
end
BigQueryService -> BigQueryService: Serialize Map to summaryArray (sort timestamps)
BigQueryService --> CLIRunner: summaryArray[]
CLIRunner -> BigQueryService: uploadLogs('bcookie_summary', summaryArray)
BigQueryService -> BigQuery: table.insert(batch of 500)
BigQuery --> BigQueryService: OK
```

## Related

- Architecture dynamic view: `dynamic-hourly-log-extraction`
- Related flows: [Hourly Log Extraction and Load](hourly-log-extraction.md), [Log Transformation and BigQuery Upload](log-transform-bigquery-upload.md), [Combined Logs Denormalization](combined-logs-denormalization.md)
