---
service: "checkout-flow-analyzer"
title: "Session List Loading"
generated: "2026-03-03"
type: flow
flow_name: "session-list-loading"
flow_type: synchronous
trigger: "User navigates to /sessions or applies a filter (bCookie, fulltext, error flags)"
participants:
  - "webUiCheFloAna"
  - "apiRoutesCheFloAna"
  - "csvDataService"
  - "fileStorageAdapter"
  - "continuumCheckoutFlowAnalyzerCsvDataFiles"
architecture_ref: "dynamic-continuumSystem-sessionAnalysisFlow"
---

# Session List Loading

## Summary

The Sessions page displays a paginated table of browser sessions (identified by `bcookie`) for the selected time window. The API route first attempts to serve data from a pre-aggregated `bcookie_summary` file for efficiency. If the summary file is unavailable or a fulltext search or raw-data override is requested, it falls back to streaming and parsing the raw PWA log file. Results are filtered by bCookie, fulltext, error flags, and purchase flags, then paginated and returned to the UI.

## Trigger

- **Type**: user-action / api-call
- **Source**: Page navigation to `/sessions`; filter form submission; pagination click
- **Frequency**: On demand — each page load or filter change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web UI | Renders session table; manages filter state; triggers API calls | `webUiCheFloAna` |
| Analysis API Routes | Handles `GET /api/csv-data` — orchestrates data source selection | `apiRoutesCheFloAna` |
| CSV Data Service | Parses, filters, paginates, and aggregates raw log data | `csvDataService` |
| File Storage Adapter | Locates and reads the appropriate CSV/ZIP file | `fileStorageAdapter` |
| CSV Data Files Store | Contains the `bcookie_summary` and `pwa_logs` ZIP archives | `continuumCheckoutFlowAnalyzerCsvDataFiles` |

## Steps

1. **Reads active time window**: The UI reads `current_time_window_id` from `localStorage` and constructs the API request.
   - From: `webUiCheFloAna`
   - To: browser `localStorage`
   - Protocol: Browser API

2. **Calls `/api/csv-data`**: The UI issues `GET /api/csv-data?timeWindowId=<id>&page=1&limit=20` with optional query parameters: `bCookie`, `fulltext`, `hasApiErrors`, `hasPurchases`, `allData`, `useRawData`.
   - From: `webUiCheFloAna`
   - To: `apiRoutesCheFloAna`
   - Protocol: HTTP GET (same-origin)

3. **Lists files for time window**: The API route calls `fileStorage.listFiles(timeWindowId)` to get the available files.
   - From: `apiRoutesCheFloAna`
   - To: `fileStorageAdapter`
   - Protocol: In-process

4. **Selects data source (optimized path)**: If `useRawData` is false and no `fulltext` filter is present, the API looks for a `bcookie_summary` file in the file list and delegates to `csvDataService.processFromSummaryFile()`.
   - From: `apiRoutesCheFloAna`
   - To: `csvDataService`
   - Protocol: In-process

5. **Reads and decompresses summary file**: The CSV Data Service calls `fileStorageAdapter.readFile(summaryFile.id)`. The File Storage Adapter reads the file from disk, auto-detects the compression format (adm-zip → gunzip → unzip → plain text), and returns the CSV content as a string.
   - From: `csvDataService` → `fileStorageAdapter`
   - To: `continuumCheckoutFlowAnalyzerCsvDataFiles`
   - Protocol: Node.js `fs.readFile` + zlib/adm-zip decompression

6. **Parses and filters (summary path)**: Papa Parse streams the CSV content. Rows are filtered by `bCookie`, `hasApiErrors`, and `hasPurchases` flags. Results are paginated using `page` and `limit` parameters.
   - From: `csvDataService`
   - To: in-process
   - Protocol: In-process (Papa Parse streaming)

7. **Falls back to raw PWA logs** (when summary unavailable, `fulltext` filter is active, or `useRawData=true`): The API locates the `pwa_logs` file, reads and decompresses it, then delegates to `csvDataService.processRawDataWithFiltering()` (with `bCookie`/`fulltext` filters) or `csvDataService.processRawDataUnfiltered()`.
   - From: `apiRoutesCheFloAna` → `csvDataService` → `fileStorageAdapter`
   - To: `continuumCheckoutFlowAnalyzerCsvDataFiles`
   - Protocol: In-process + filesystem I/O

8. **Returns paginated session list**: The API serializes the filtered, paginated result as JSON including `data`, `metadata.pagination`, `metadata.totalCount`, and `metadata.source` (`bcookie_summary` or `csv-file`).
   - From: `apiRoutesCheFloAna`
   - To: `webUiCheFloAna`
   - Protocol: HTTP 200 JSON

9. **Renders session table**: The UI displays bCookie rows with columns: event count, first/last seen, purchase flag, API error flag, session count, request IDs. Pagination controls update `page` query parameter.
   - From: `webUiCheFloAna`
   - To: User (browser render)
   - Protocol: React render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `timeWindowId` | API returns `404` | UI shows "No time window selected" message |
| No PWA file found for time window | API returns `404` with available time windows | UI shows error alert |
| File decompression failure | API throws; returns `500` with error message | UI shows error alert |
| Empty result set (all filtered out) | API returns `200` with empty `data` array | UI shows "No sessions found" state |

## Sequence Diagram

```
WebUI            ApiRoutes       CsvDataService    FileStorageAdapter    DataFiles
  |                  |                |                  |                  |
  |--GET /csv-data-->|                |                  |                  |
  |                  |--listFiles()-->|                  |                  |
  |                  |               |--listFiles()----> |                  |
  |                  |               |                  |--readdir()------> |
  |                  |               |                  |<--filenames-------|
  |                  |<--CSVFileInfo[]                  |                  |
  |                  |                                  |                  |
  |     [summary file available, no fulltext filter]    |                  |
  |                  |--processFromSummaryFile()-------> |                  |
  |                  |               |--readFile(id)--> |                  |
  |                  |               |                  |--readFile()-----> |
  |                  |               |                  |<--compressed buf--|
  |                  |               |                  |--decompress()     |
  |                  |               |<--CSV string------                  |
  |                  |               |--Papa.parse()     |                  |
  |                  |               |--filter+paginate  |                  |
  |                  |<--CSVDataResponse                 |                  |
  |<--200 {data,metadata}--|         |                  |                  |
  |--render table    |               |                  |                  |
```

## Related

- Architecture dynamic view: `dynamic-continuumSystem-sessionAnalysisFlow`
- Related flows: [Time Window Selection](time-window-selection.md), [Session Detail Analysis](session-detail-analysis.md)
