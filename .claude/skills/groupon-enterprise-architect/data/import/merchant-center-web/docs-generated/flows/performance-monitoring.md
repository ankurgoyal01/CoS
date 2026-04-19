---
service: "merchant-center-web"
title: "Performance Monitoring"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "performance-monitoring"
flow_type: synchronous
trigger: "Merchant views the performance dashboard for their active campaigns"
participants:
  - "merchantCenterWebSPA"
  - "continuumAidg"
architecture_ref: "dynamic-continuum-performance-monitoring"
---

# Performance Monitoring

## Summary

The performance monitoring flow enables merchants to view live and historical performance metrics for their active campaigns directly in the portal dashboard. The SPA fetches KPI data from AIDG on page load and periodically refreshes it via react-query's background refetch. Metrics are rendered using chart.js visualizations and summary stat panels, giving merchants insight into deal views, purchases, revenue, and redemption rates.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates to `/` (dashboard) or a campaign detail view.
- **Frequency**: On-demand; react-query also performs background refetches at a configured staleness interval.

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Views campaign performance metrics on the dashboard | N/A (human actor) |
| Merchant Center Web SPA | Fetches and renders performance data | `merchantCenterWebSPA` |
| AIDG | Provides KPI data, aggregated metrics, and trend data | `continuumAidg` |

## Steps

1. **Merchant Lands on Dashboard**: Merchant navigates to `/` or a specific campaign's performance view.
   - From: Merchant (browser)
   - To: `merchantCenterWebSPA`
   - Protocol: Client-side route transition

2. **SPA Initiates Data Fetch**: react-query checks cache staleness. If data is stale or absent, SPA dispatches a GET request to the proxied AIDG endpoint for performance KPIs.
   - From: `merchantCenterWebSPA`
   - To: `continuumAidg`
   - Protocol: REST / HTTPS (proxied, Bearer token)

3. **SPA Renders Loading State**: While awaiting AIDG response, SPA renders skeleton loaders or loading indicators in the dashboard panels.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render

4. **AIDG Returns KPI Data**: AIDG responds with aggregated performance metrics: views, clicks, purchases, revenue, redemption counts, trend data.
   - From: `continuumAidg`
   - To: `merchantCenterWebSPA`
   - Protocol: REST / HTTPS

5. **SPA Renders Performance Charts and Stats**: SPA updates the dashboard panels with received data, rendering line/bar charts via chart.js and numeric KPI summaries.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render

6. **Background Refresh**: react-query background refetch fires after the configured staleTime interval, silently updating the displayed data without a loading spinner (if previously loaded).
   - From: `merchantCenterWebSPA`
   - To: `continuumAidg`
   - Protocol: REST / HTTPS (proxied, Bearer token)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AIDG unavailable | react-query error state after retries exhausted | Dashboard panels show error state with retry button |
| Partial AIDG response (some metrics missing) | SPA renders available metrics; missing sections show empty state | Merchant sees partial dashboard |
| Stale cache served while AIDG is slow | react-query serves cached data while background refetch runs | Merchant sees slightly outdated data momentarily |
| Authentication expiry during background refresh | 401 response; route guard triggers re-auth | Merchant redirected to Doorman login |

## Sequence Diagram

```
Merchant -> merchantCenterWebSPA: Navigate to dashboard /
merchantCenterWebSPA -> merchantCenterWebSPA: Check react-query cache (stale?)
merchantCenterWebSPA -> continuumAidg: GET /performance/kpis?merchantId=...
merchantCenterWebSPA -> Merchant: Render skeleton loaders
continuumAidg --> merchantCenterWebSPA: KPI data JSON (views, revenue, redemptions)
merchantCenterWebSPA -> Merchant: Render charts + KPI panels (chart.js)
...after staleTime interval...
merchantCenterWebSPA -> continuumAidg: GET /performance/kpis?merchantId=... (background)
continuumAidg --> merchantCenterWebSPA: Updated KPI data
merchantCenterWebSPA -> Merchant: Silently update charts
```

## Related

- Architecture dynamic view: `dynamic-continuum-performance-monitoring`
- Related flows: [Report Generation](report-generation.md), [Voucher Redemption](voucher-redemption.md)
