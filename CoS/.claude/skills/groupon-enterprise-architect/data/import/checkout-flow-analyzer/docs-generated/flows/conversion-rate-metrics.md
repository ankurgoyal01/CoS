---
service: "checkout-flow-analyzer"
title: "Conversion Rate and Platform Metrics"
generated: "2026-03-03"
type: flow
flow_name: "conversion-rate-metrics"
flow_type: synchronous
trigger: "User navigates to /top-stats dashboard"
participants:
  - "webUiCheFloAna"
  - "apiRoutesCheFloAna"
  - "fileStorageAdapter"
  - "continuumCheckoutFlowAnalyzerCsvDataFiles"
architecture_ref: "dynamic-continuumSystem-sessionAnalysisFlow"
---

# Conversion Rate and Platform Metrics

## Summary

The Top Stats dashboard (`/top-stats`) provides aggregate metrics for the selected time window without requiring per-session navigation. It computes two metric sets: the checkout conversion funnel (View → Attempt → Success rates) and the device platform distribution (by unique browser session). Both are calculated by streaming the raw PWA log file through Papa Parse and aggregating per-bCookie state. Results are displayed as metric cards and charts.

## Trigger

- **Type**: user-action
- **Source**: Analyst navigates to `/top-stats`
- **Frequency**: On demand — once per page load

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web UI (Top Stats page) | Renders metric cards, `ConversionRateChart`, and `PlatformDistributionChart` | `webUiCheFloAna` |
| Analysis API Routes | Handles `GET /api/conversion-rate` and `GET /api/platform-distribution` | `apiRoutesCheFloAna` |
| File Storage Adapter | Reads and decompresses the PWA log ZIP for the selected time window | `fileStorageAdapter` |
| CSV Data Files Store | Contains the `pwa_logs` ZIP archive | `continuumCheckoutFlowAnalyzerCsvDataFiles` |

## Steps

### Conversion Rate Calculation

1. **Requests conversion rate**: The UI reads `timeWindowId` from `localStorage` and calls `GET /api/conversion-rate?timeWindowId=<id>`.
   - From: `webUiCheFloAna`
   - To: `apiRoutesCheFloAna`
   - Protocol: HTTP GET (same-origin)

2. **Locates PWA file**: The handler calls `fileStorage.listFiles(timeWindowId)` and identifies the file with `type === 'pwa'`.
   - From: `apiRoutesCheFloAna`
   - To: `fileStorageAdapter`
   - Protocol: In-process

3. **Reads and decompresses PWA log**: Calls `fileStorage.readFile(pwaFile.id)` which decompresses the ZIP using adm-zip and returns the CSV string.
   - From: `fileStorageAdapter`
   - To: `continuumCheckoutFlowAnalyzerCsvDataFiles`
   - Protocol: Node.js filesystem I/O + adm-zip decompression

4. **Streams and aggregates per bCookie**: Papa Parse processes the CSV row by row. For each row, the handler updates a `Map<bCookie, sessionState>` tracking:
   - `hasCheckoutView`: event `name` contains `CHECKOUT-VIEW`
   - `hasCheckoutAttempt`: event `name` contains `CHECKOUT-ATTEMPT` or `MULTI-ORDER-INPUT`
   - `hasCheckoutSuccess`: event `name` contains `CHECKOUT-FINISHED` or `SIGNIFIED-SESSION-PRUNE`
   - From: `apiRoutesCheFloAna`
   - To: in-process
   - Protocol: In-process (Papa Parse streaming)

5. **Computes conversion rates**: Only sessions with `hasCheckoutView=true` are counted as valid. Rates are calculated:
   - `viewToAttemptRate = totalAttempts / totalViews * 100`
   - `attemptToSuccessRate = totalSuccesses / totalAttempts * 100`
   - `viewToSuccessRate = totalSuccesses / totalViews * 100`
   - From: `apiRoutesCheFloAna`
   - To: in-process
   - Protocol: In-process

6. **Returns conversion metrics**: API responds with `ConversionRateMetrics`: `totalCheckoutViews`, `totalCheckoutAttempts`, `totalCheckoutSuccesses`, `invalidSessions`, three rate percentages, `timeWindowId`, `lastUpdated`.
   - From: `apiRoutesCheFloAna`
   - To: `webUiCheFloAna`
   - Protocol: HTTP 200 JSON

### Platform Distribution Calculation

7. **Requests platform distribution**: The UI calls `GET /api/platform-distribution?timeWindowId=<id>` in parallel with the conversion rate request.
   - From: `webUiCheFloAna`
   - To: `apiRoutesCheFloAna`
   - Protocol: HTTP GET (same-origin)

8. **Reads PWA log (same file)**: The handler locates and decompresses the same PWA log file.
   - From: `apiRoutesCheFloAna` → `fileStorageAdapter`
   - To: `continuumCheckoutFlowAnalyzerCsvDataFiles`
   - Protocol: In-process + filesystem I/O

9. **Aggregates platform per bCookie**: Papa Parse streams rows. For each bCookie, the handler records the `platform` field (if present) or infers the platform from the `data.userAgent` field using `determinePlatform()` from `src/features/analysis/utils/analysisUtils.ts`.
   - From: `apiRoutesCheFloAna`
   - To: in-process
   - Protocol: In-process (Papa Parse streaming)

10. **Counts and ranks platforms**: Platform counts are aggregated across unique bCookies. Unknown platforms are counted separately. Results are sorted by count descending and percentage is computed relative to total unique browsers.
    - From: `apiRoutesCheFloAna`
    - To: in-process
    - Protocol: In-process

11. **Returns platform distribution**: API responds with `PlatformDistributionMetrics`: `platforms` (name, count, percentage array), `totalSessions`, `unknownPlatforms`, `lastUpdated`.
    - From: `apiRoutesCheFloAna`
    - To: `webUiCheFloAna`
    - Protocol: HTTP 200 JSON

12. **Renders Top Stats dashboard**: The UI displays the conversion funnel rates in `ConversionRateChart` (Recharts) and the platform breakdown in `PlatformDistributionChart`. Metric cards show raw counts alongside the calculated rates.
    - From: `webUiCheFloAna`
    - To: User (browser render)
    - Protocol: React render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `timeWindowId` parameter | API returns `400` with error message | UI shows error; charts not rendered |
| No PWA file found for time window | API returns `500` with null data | UI shows error alert for that metric section |
| File read or decompression failure | `calculateConversionRate()` returns `null`; API returns `500` | UI shows error for the affected metric |
| No sessions with `CHECKOUT-VIEW` event | `totalCheckoutViews = 0`; rates return `0` | UI shows zero rates; may indicate wrong log file or event naming mismatch |
| All bCookies have unknown platform | `unknownPlatforms` equals `totalSessions` | Platform chart shows all sessions as unknown; no actionable error |

## Sequence Diagram

```
WebUI (Top Stats)    ApiRoutes        FileStorageAdapter    DataFiles
  |                      |                  |                   |
  | [parallel]           |                  |                   |
  |--GET /conversion-rate?timeWindowId=X--> |                   |
  |--GET /platform-distribution?timeWindowId=X>|               |
  |                      |                  |                   |
  |                      |--listFiles(id)-->|                   |
  |                      |<--CSVFileInfo[]--|                   |
  |                      |--readFile(pwa.id)-->                |
  |                      |                  |--fs.readFile()--> |
  |                      |                  |<--ZIP buffer------|
  |                      |                  |--adm-zip extract()|
  |                      |<--CSV string-----|                   |
  |                      |--Papa.parse() streaming              |
  |                      |  [per row: update bCookie state map] |
  |                      |--compute rates / platform counts     |
  |                      |                  |                   |
  |<--ConversionRateMetrics---|             |                   |
  |<--PlatformDistributionMetrics--|        |                   |
  |                      |                  |                   |
  |--render ConversionRateChart             |                   |
  |--render PlatformDistributionChart       |                   |
```

## Related

- Architecture dynamic view: `dynamic-continuumSystem-sessionAnalysisFlow`
- Related flows: [Time Window Selection](time-window-selection.md), [Session List Loading](session-list-loading.md)
