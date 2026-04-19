---
service: "checkout-flow-analyzer"
title: "Time Window Selection"
generated: "2026-03-03"
type: flow
flow_name: "time-window-selection"
flow_type: synchronous
trigger: "User opens the home page and selects a date range from the time-window picker"
participants:
  - "webUiCheFloAna"
  - "apiRoutesCheFloAna"
  - "fileStorageAdapter"
  - "continuumCheckoutFlowAnalyzerCsvDataFiles"
architecture_ref: "dynamic-continuumSystem-sessionAnalysisFlow"
---

# Time Window Selection

## Summary

Before any session data can be browsed, the analyst must select a time window. The home page calls the API to discover all available log archives, groups them by date range, and presents a picker. When the analyst confirms a selection, the app validates that the time window exists, persists the selection, and redirects the browser to the `/sessions` page.

## Trigger

- **Type**: user-action
- **Source**: Analyst opens the application home page (`/`) and chooses a time window
- **Frequency**: On demand — once per analysis session (persisted in `localStorage` until changed)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web UI | Renders the time-window picker; submits the selection | `webUiCheFloAna` |
| Analysis API Routes | Handles `/api/csv-time-windows` (list) and `/api/select-csv` (select) | `apiRoutesCheFloAna` |
| File Storage Adapter | Scans the data-files directory, parses filenames, groups into time windows | `fileStorageAdapter` |
| CSV Data Files Store | Source directory containing all log archives | `continuumCheckoutFlowAnalyzerCsvDataFiles` |

## Steps

1. **Requests available time windows**: The UI calls `GET /api/csv-time-windows` on page load.
   - From: `webUiCheFloAna`
   - To: `apiRoutesCheFloAna`
   - Protocol: HTTP GET (same-origin)

2. **Scans data-files directory**: The File Storage Adapter reads the `src/assets/data-files/` directory and enumerates all `.csv` and `.csv.zip` files.
   - From: `fileStorageAdapter`
   - To: `continuumCheckoutFlowAnalyzerCsvDataFiles`
   - Protocol: Node.js `fs.readdir` (local filesystem)

3. **Parses filenames and groups into time windows**: Each filename is matched against the pattern `(pwa|orders|proxy|lazlo|bcookie_summary)(_logs)?_us_YYYYMMDD_HHMMSS_YYYYMMDD_HHMMSS.csv(.zip)?`. Files with the same date-time range are grouped into a single `TimeWindowInfo` object. A time window is marked `isComplete: true` when all four main types (`pwa`, `orders`, `proxy`, `lazlo`) are present.
   - From: `fileStorageAdapter`
   - To: in-process
   - Protocol: In-process TypeScript

4. **Returns time window list**: The API route serializes the grouped time windows (sorted newest-first) as JSON and responds to the UI.
   - From: `apiRoutesCheFloAna`
   - To: `webUiCheFloAna`
   - Protocol: HTTP 200 JSON

5. **User selects a time window**: The analyst chooses a date range from the UI picker and submits.
   - From: `webUiCheFloAna` (user action)
   - To: `webUiCheFloAna`
   - Protocol: Browser UI interaction

6. **Posts selection to API**: The UI calls `POST /api/select-csv` with `{ "timeWindowId": "<id>" }`.
   - From: `webUiCheFloAna`
   - To: `apiRoutesCheFloAna`
   - Protocol: HTTP POST JSON (same-origin)

7. **Validates and persists selection**: The API verifies the `timeWindowId` exists in the available time windows list. If valid, it stores the selection in the `TimeWindowStore` (server-side in-process store backed by `localStorage` on the client) and lists available files for the window.
   - From: `apiRoutesCheFloAna`
   - To: `fileStorageAdapter`
   - Protocol: In-process

8. **Responds with redirect instruction**: The API returns `{ "success": true, "redirectTo": "/sessions", "availableFiles": [...] }`.
   - From: `apiRoutesCheFloAna`
   - To: `webUiCheFloAna`
   - Protocol: HTTP 200 JSON

9. **Persists selection client-side and navigates**: The UI stores the `timeWindowId` in `localStorage` (key: `current_time_window_id`) and navigates the browser to `/sessions`.
   - From: `webUiCheFloAna`
   - To: browser localStorage + Next.js router
   - Protocol: Browser API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No files in `src/assets/data-files/` | API returns empty `timeWindows` array | UI shows empty picker; analyst must add log files |
| File does not match naming pattern | `parseFileName()` returns `null`; file is silently skipped | File is excluded from the time window list |
| `timeWindowId` not found on POST | API returns `404` with error message | UI shows error; no navigation occurs |
| Missing `timeWindowId` in POST body | API returns `400` | UI shows validation error |

## Sequence Diagram

```
WebUI                ApiRoutes         FileStorageAdapter    DataFiles
  |                      |                    |                  |
  |--GET /csv-time-windows-->                 |                  |
  |                      |--listFiles()-----> |                  |
  |                      |                   |--readdir()------> |
  |                      |                   |<--filenames-------|
  |                      |                   |--parseFileName()  |
  |                      |                   |--groupByWindow()  |
  |                      |<--TimeWindowInfo[]--|                  |
  |<--200 {timeWindows}--|                   |                  |
  |                      |                   |                  |
  |  [user selects]      |                   |                  |
  |                      |                   |                  |
  |--POST /select-csv--> |                   |                  |
  |                      |--getTimeWindows()->|                  |
  |                      |<--TimeWindowInfo[]--|                  |
  |                      |--validate exists  |                  |
  |                      |--setTimeWindowId()|                  |
  |                      |--listFiles(id)--> |                  |
  |                      |<--CSVFileInfo[]---|                  |
  |<--200 {redirectTo: /sessions}--|         |                  |
  |--localStorage.setItem(timeWindowId)      |                  |
  |--navigate to /sessions                   |                  |
```

## Related

- Architecture dynamic view: `dynamic-continuumSystem-sessionAnalysisFlow`
- Related flows: [Session List Loading](session-list-loading.md), [Session Detail Analysis](session-detail-analysis.md)
