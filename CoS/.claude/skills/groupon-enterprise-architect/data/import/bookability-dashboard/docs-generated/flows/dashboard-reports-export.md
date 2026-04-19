---
service: "bookability-dashboard"
title: "Dashboard Reports and Export"
generated: "2026-03-03"
type: flow
flow_name: "dashboard-reports-export"
flow_type: synchronous
trigger: "User navigates to Reports view or clicks CSV export"
participants:
  - "continuumBookabilityDashboardWeb"
  - "bookDash_appShell"
  - "bookDash_partnerServiceClient"
  - "bookDash_reportExporter"
  - "apiProxy"
  - "continuumPartnerService"
architecture_ref: "dynamic-bookability-dashboard-data-fetch"
---

# Dashboard Reports and Export

## Summary

The Reports view fetches aggregated time-to-bookability metrics from Partner Service for a user-selected date range and displays total, success, and failure counts broken down by booking platform (overall, Square, Mindbody, Mindbody2, Booker). Users can also export merchant and deal data to CSV at any time via the Report Exporter component.

## Trigger

- **Type**: user-action
- **Source**: User clicks the "Reports" navigation button; or user clicks a CSV export button in any view
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dashboard App Shell | Renders the Reports view; passes deal data to report components | `bookDash_appShell` |
| Partner Service Client | Fetches aggregated dashboard reports from Partner Service | `bookDash_partnerServiceClient` |
| Report Exporter | Transforms merchant/deal data into downloadable CSV files | `bookDash_reportExporter` |
| API Proxy | Routes report API requests to Partner Service | `apiProxy` |
| Partner Service | Returns pre-aggregated time-to-bookability report data | `continuumPartnerService` |

## Steps

### Reports view load

1. **Render Reports component**: User navigates to `?view=reports`. `AppShell` renders the `Reports` component, passing the current `deals` array from state.
   - From: `bookDash_appShell`
   - To: Browser DOM
   - Protocol: In-process

2. **User selects date range**: `DateFilter` component allows selection of a month (e.g., "February 2026"). The component computes `earliest` (start of month ISO 8601) and `latest` (end of month ISO 8601) values. A 500 ms debounce prevents rapid consecutive API calls.
   - From: Browser (user interaction)
   - To: `Reports` component state
   - Protocol: In-process

3. **Fetch report data**: `fetchDashboardReports(earliest, latest, signal)` calls `fetchPartnerConfigurations()` to collect all active acquisition method IDs, then sends:
   `GET /v1/groupon/simulator/dashboard-reports?acquisitionMethodIds={ids}&clientId=tpis&earliest={earliest}&latest={latest}`
   - From: `bookDash_partnerServiceClient`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (HTTPS GET, with `AbortSignal` for cancellation on date change)

4. **Receive aggregated metrics**: Partner Service returns a `DashboardReportsResponse` with fields:
   - `timeToBookabilityTotal`, `timeToBookabilitySuccess`, `timeToBookabilityFailed` (overall)
   - Per-platform variants: `...Square`, `...Mindbody`, `...Mindbody2`, `...Booker`
   - From: `continuumPartnerService`
   - To: `bookDash_partnerServiceClient`
   - Protocol: REST (JSON response)

5. **Display report cards**: `ReportCard` components render the metrics as total/success/failed counts for each platform. A date-range filter summary is shown above the cards.
   - From: `bookDash_appShell`
   - To: Browser DOM
   - Protocol: In-process

### CSV export

6. **User requests CSV export**: User clicks an export button. `bookDash_reportExporter` (`csvExport.ts`) transforms the in-memory `deals` or merchant data into CSV rows using JavaScript's `Blob` and `URL.createObjectURL()`.
   - From: `bookDash_reportExporter`
   - To: Browser (file download trigger)
   - Protocol: In-process (no API call — data is already in memory)

7. **File download**: Browser triggers a file download with the generated CSV content. No server-side request is made.
   - From: Browser
   - To: User filesystem
   - Protocol: Browser file API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Dashboard reports API returns HTTP error | Error thrown and logged; caught in `Reports` component | Error state displayed; empty report cards |
| Request aborted (date changed before response) | `AbortSignal` cancels the in-flight fetch | No stale data rendered; new request starts for updated date range |
| Partner configurations unavailable | `fetchPartnerConfigurations()` throws; propagates to Reports | Reports view shows error state |
| CSV export with empty data | No file generated; user sees empty download | No crash; empty CSV file |

## Sequence Diagram

```
User -> AppShell: Navigate to ?view=reports
AppShell -> Browser: Render Reports component with deals[]
User -> Reports: Select date range (month picker)
Reports -> Reports: Debounce 500ms
Reports -> PartnerServiceClient: fetchDashboardReports(earliest, latest, signal)
PartnerServiceClient -> PartnerService: GET /v1/partner_configurations?monitoring=true
PartnerService --> PartnerServiceClient: acquisitionMethodIds[]
PartnerServiceClient -> PartnerService: GET /v1/groupon/simulator/dashboard-reports?acquisitionMethodIds=...&earliest=...&latest=...
PartnerService --> PartnerServiceClient: DashboardReportsResponse
PartnerServiceClient --> Reports: { timeToBookabilityTotal, ...Square, ...Mindbody, ...Booker }
Reports -> Browser: Render ReportCard components with metrics

User -> AppShell: Click CSV Export
AppShell -> ReportExporter: generateCsv(deals)
ReportExporter -> Browser: Blob + URL.createObjectURL + click <a>
Browser -> User: File download triggered
```

## Related

- Architecture dynamic view: `dynamic-bookability-dashboard-data-fetch`
- Related flows: [Dashboard Data Load](dashboard-data-load.md)
