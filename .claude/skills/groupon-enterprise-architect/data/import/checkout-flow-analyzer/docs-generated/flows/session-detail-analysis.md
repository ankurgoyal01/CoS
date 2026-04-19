---
service: "checkout-flow-analyzer"
title: "Session Detail Analysis"
generated: "2026-03-03"
type: flow
flow_name: "session-detail-analysis"
flow_type: synchronous
trigger: "User clicks a bCookie in the session list to open the session detail page"
participants:
  - "webUiCheFloAna"
  - "apiRoutesCheFloAna"
  - "csvDataService"
  - "fileStorageAdapter"
  - "continuumCheckoutFlowAnalyzerCsvDataFiles"
architecture_ref: "dynamic-continuumSystem-sessionAnalysisFlow"
---

# Session Detail Analysis

## Summary

The session detail page (`/sessions/[bCookie]`) gives an analyst a unified view of everything that happened during a single browser session. It loads event rows for the selected bCookie from four log sources in parallel — PWA events, proxy-layer requests, Lazlo backend calls, and orders-service events — and renders them as a correlated event timeline. This enables engineers to trace a checkout failure or drop-off from the frontend event all the way through backend service calls.

## Trigger

- **Type**: user-action
- **Source**: Analyst clicks a bCookie link in the `/sessions` session list
- **Frequency**: On demand — per session investigation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web UI (Session Detail page) | Renders event timeline, backend logs section, request groups, and user summary | `webUiCheFloAna` |
| Analysis API Routes | Handles four parallel log requests and the CSV data endpoint | `apiRoutesCheFloAna` |
| CSV Data Service | Parses and filters raw PWA log data by bCookie | `csvDataService` |
| File Storage Adapter | Reads and decompresses the relevant log files for the time window | `fileStorageAdapter` |
| CSV Data Files Store | Contains all four log type archives for the selected time window | `continuumCheckoutFlowAnalyzerCsvDataFiles` |

## Steps

1. **Navigates to session detail**: The browser navigates to `/sessions/<bCookie>`. The URL encodes the bCookie value as a path parameter.
   - From: `webUiCheFloAna` (user click)
   - To: Next.js App Router
   - Protocol: Browser navigation

2. **Loads PWA session events**: The page calls `GET /api/csv-data?timeWindowId=<id>&bCookie=<bCookie>&allData=true` to load all PWA log rows for the session (no pagination).
   - From: `webUiCheFloAna`
   - To: `apiRoutesCheFloAna`
   - Protocol: HTTP GET (same-origin)

3. **Loads proxy logs**: Simultaneously, the page calls `GET /api/proxy-logs?timeWindowId=<id>&bCookie=<bCookie>`.
   - From: `webUiCheFloAna`
   - To: `apiRoutesCheFloAna`
   - Protocol: HTTP GET (same-origin)

4. **Loads Lazlo logs**: The page calls `GET /api/lazlo-logs?timeWindowId=<id>&bCookie=<bCookie>` to retrieve Lazlo backend log rows for the session.
   - From: `webUiCheFloAna`
   - To: `apiRoutesCheFloAna`
   - Protocol: HTTP GET (same-origin)

5. **Loads orders logs**: The page calls `GET /api/orders-logs?timeWindowId=<id>&bCookie=<bCookie>` to retrieve any order events for the session.
   - From: `webUiCheFloAna`
   - To: `apiRoutesCheFloAna`
   - Protocol: HTTP GET (same-origin)

6. **Reads and decompresses each log file**: Each API handler calls `fileStorage.listFiles(timeWindowId)`, locates the file of the relevant type (`pwa`, `proxy`, `lazlo`, `orders`), and calls `fileStorage.readFile(fileId)`. The File Storage Adapter decompresses the ZIP/gzip archive and returns the CSV content.
   - From: `apiRoutesCheFloAna`
   - To: `fileStorageAdapter` → `continuumCheckoutFlowAnalyzerCsvDataFiles`
   - Protocol: In-process + Node.js filesystem I/O

7. **Parses and filters by bCookie**: Each handler passes the CSV content to Papa Parse. Rows are filtered by the bCookie value. The proxy/lazlo/orders handlers search across multiple possible column names (`bcookie`, `b`, `data.cookies.b`, `user.bcookie`, etc.) to find the bCookie column.
   - From: each `apiRoutesCheFloAna` handler
   - To: in-process (Papa Parse)
   - Protocol: In-process

8. **Optionally loads Lazlo logs by request ID**: The UI may call `POST /api/lazlo-logs?timeWindowId=<id>` with a body `{ "requestIds": ["id1", "id2"] }` to cross-correlate specific request IDs from the PWA timeline with Lazlo backend entries.
   - From: `webUiCheFloAna`
   - To: `apiRoutesCheFloAna`
   - Protocol: HTTP POST JSON (same-origin)

9. **Returns all four log datasets**: Each API handler returns filtered rows with metadata (`rowCount`, `filtered`, `bCookie`, `source`, `timeWindowId`).
   - From: `apiRoutesCheFloAna`
   - To: `webUiCheFloAna`
   - Protocol: HTTP 200 JSON

10. **Renders event timeline**: The UI merges and sorts all events chronologically and renders the `EventTimelineSection`, `BackendLogsSection`, `RequestGroupsSection`, `ValidationFailuresSection`, and `UserFlowVisualization` (Sankey) components.
    - From: `webUiCheFloAna`
    - To: User (browser render)
    - Protocol: React render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Log file not found for type | API returns empty `data` array with `success: true` (for lazlo/proxy/orders), or `404` (for pwa) | UI shows empty section for that log type; other sections still render |
| File decompression failure | API returns `500` with error message | UI shows error in the relevant log section |
| No rows match the bCookie filter | API returns `200` with empty `data` array | UI shows "No data" state for that section |
| bCookie column not found in log | Handler logs warning; returns unfiltered data | Analyst may see all rows rather than per-session rows |

## Sequence Diagram

```
WebUI (Session Detail)    ApiRoutes      FileStorageAdapter    DataFiles
  |                           |               |                   |
  | [parallel requests]       |               |                   |
  |--GET /csv-data?bCookie=X->|               |                   |
  |--GET /proxy-logs?bCookie->|               |                   |
  |--GET /lazlo-logs?bCookie->|               |                   |
  |--GET /orders-logs?bCookie>|               |                   |
  |                           |               |                   |
  |                           |--readFile(pwa.id)-->              |
  |                           |               |--readFile()-----> |
  |                           |               |<--ZIP buffer------|
  |                           |               |--decompress()     |
  |                           |<--CSV string--|                   |
  |                           |--Papa.parse() + filter by bCookie |
  |                           | [same for proxy, lazlo, orders]   |
  |                           |               |                   |
  |<--pwa rows----------------|               |                   |
  |<--proxy rows--------------|               |                   |
  |<--lazlo rows--------------|               |                   |
  |<--orders rows-------------|               |                   |
  |                           |               |                   |
  | [optional: lookup by requestId]           |                   |
  |--POST /lazlo-logs {requestIds:[...]}----> |                   |
  |<--filtered lazlo rows-----|               |                   |
  |                           |               |                   |
  |--render EventTimeline, BackendLogs, RequestGroups             |
```

## Related

- Architecture dynamic view: `dynamic-continuumSystem-sessionAnalysisFlow`
- Related flows: [Session List Loading](session-list-loading.md), [Time Window Selection](time-window-selection.md)
