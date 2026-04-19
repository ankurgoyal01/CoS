---
service: "merchant-center-web"
title: "Report Generation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "report-generation"
flow_type: synchronous
trigger: "Merchant requests a performance or sales report from the reporting section"
participants:
  - "merchantCenterWebSPA"
  - "continuumAidg"
architecture_ref: "dynamic-continuum-report-generation"
---

# Report Generation

## Summary

The report generation flow enables merchants to generate and view performance reports for their deals and campaigns. The merchant selects a report type and date range; the SPA fetches aggregated analytics data from AIDG and renders it in charts and tables using chart.js. Reports can cover sales volume, voucher redemptions, revenue, and deal performance metrics.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates to the reporting section and selects report parameters (type, date range, deal filter).
- **Frequency**: On-demand.

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Selects report parameters, views rendered report | N/A (human actor) |
| Merchant Center Web SPA | Renders parameter form, fetches data, renders charts | `merchantCenterWebSPA` |
| AIDG | Provides aggregated analytics and performance data | `continuumAidg` |

## Steps

1. **Merchant Opens Reporting Section**: Merchant navigates to the reports area of the portal.
   - From: Merchant (browser)
   - To: `merchantCenterWebSPA`
   - Protocol: Client-side route transition

2. **Render Report Parameter Form**: SPA renders a form for selecting report type (e.g., sales summary, redemption report), date range, and optional deal filter.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render

3. **Merchant Sets Parameters and Requests Report**: Merchant selects parameters and triggers the report request.
   - From: Merchant (browser)
   - To: `merchantCenterWebSPA`
   - Protocol: In-browser (direct)

4. **SPA Fetches Report Data from AIDG**: SPA issues a GET request to the proxied AIDG endpoint with query parameters encoding the report type, date range, and merchant/deal scope.
   - From: `merchantCenterWebSPA`
   - To: `continuumAidg`
   - Protocol: REST / HTTPS (proxied, Bearer token)

5. **AIDG Returns Aggregated Data**: AIDG processes the query and returns aggregated metrics data (JSON).
   - From: `continuumAidg`
   - To: `merchantCenterWebSPA`
   - Protocol: REST / HTTPS

6. **SPA Renders Report**: SPA transforms the AIDG response and renders charts (chart.js) and summary tables in the report view.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AIDG unavailable | react-query error state; error message in report panel | Merchant sees error; can retry |
| No data for selected parameters | AIDG returns empty dataset | SPA renders "no data available" empty state |
| Large date range causes slow response | react-query loading state with spinner | Merchant waits; no timeout shown unless request exceeds react-query timeout |
| Authentication failure | 401 from AIDG proxy; route guard clears session | Merchant redirected to login |

## Sequence Diagram

```
Merchant -> merchantCenterWebSPA: Select report type + date range
merchantCenterWebSPA -> continuumAidg: GET /reports?type=...&from=...&to=...
continuumAidg --> merchantCenterWebSPA: Aggregated metrics JSON
merchantCenterWebSPA -> merchantCenterWebSPA: Transform data for chart.js
merchantCenterWebSPA -> Merchant: Render charts + summary tables
```

## Related

- Architecture dynamic view: `dynamic-continuum-report-generation`
- Related flows: [Performance Monitoring](performance-monitoring.md), [Voucher Redemption](voucher-redemption.md)
