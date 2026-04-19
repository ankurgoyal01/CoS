---
service: "goods-vendor-portal"
title: "Analytics and Insights Reporting"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "analytics-and-insights-reporting"
flow_type: synchronous
trigger: "Merchant navigates to the analytics or insights section of the portal"
participants:
  - "emberApp"
  - "goodsVendorPortal_apiClient"
  - "continuumGoodsVendorPortalWeb"
  - "gpapiApi_unk_1d2b"
architecture_ref: "dynamic-analytics-and-insights-reporting"
---

# Analytics and Insights Reporting

## Summary

The Analytics and Insights Reporting flow presents goods merchants with business performance data — sales metrics, deal performance, product trends, and revenue summaries. The portal fetches pre-aggregated insights data from GPAPI via the `/goods-gateway/insights` endpoint and renders it using `chart.js` 2.8.0 and embedded React components for data visualization widgets. This is a read-only flow; merchants consume reports but do not modify underlying data through this section.

## Trigger

- **Type**: user-action
- **Source**: Authenticated merchant navigates to the analytics or insights section
- **Frequency**: On-demand; merchants check their performance data regularly

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Views analytics dashboards and insight reports | — |
| Ember UI | Renders insights route, passes data to chart.js and React visualization components | `emberApp` |
| API Client | Fetches insights data from the proxy endpoint | `goodsVendorPortal_apiClient` |
| Nginx (portal) | Proxies insights requests to GPAPI | `continuumGoodsVendorPortalWeb` |
| GPAPI | Returns pre-aggregated insights and performance metrics for the vendor | `gpapiApi_unk_1d2b` |

## Steps

1. **Loads insights route**: Ember routes the merchant to the insights section; `emberApp` initiates a data fetch.
   - From: `emberApp` (router)
   - To: `goodsVendorPortal_apiClient`
   - Protocol: In-process (ember-data model hook)

2. **Requests insights data**: `goodsVendorPortal_apiClient` issues `GET /goods-gateway/insights` with optional query parameters for date range, product filter, or deal filter.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx)
   - Protocol: REST/HTTPS

3. **Proxies to GPAPI**: Nginx forwards the insights request to GPAPI.
   - From: `continuumGoodsVendorPortalWeb`
   - To: `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

4. **Returns insights payload**: GPAPI returns the pre-aggregated metrics payload (sales totals, deal performance, product-level breakdowns) for the vendor.
   - From: `gpapiApi_unk_1d2b`
   - To: `goodsVendorPortal_apiClient` (via Nginx)
   - Protocol: REST/HTTPS

5. **Populates ember-data store**: `emberApp` stores the insights records and passes the data to the insights view layer.
   - From: `goodsVendorPortal_apiClient`
   - To: `emberApp`
   - Protocol: In-process

6. **Renders charts and tables**: `emberApp` passes insights data to `chart.js` components (rendered via Ember component wrappers) and React-based visualization widgets to display bar charts, line graphs, and summary tables.
   - From: `emberApp`
   - To: Merchant browser (chart.js / React in-browser)
   - Protocol: In-browser rendering

7. **Merchant filters or drills down (optional)**: Merchant adjusts date range or selects a specific product or deal; `emberApp` re-issues `GET /goods-gateway/insights` with updated query parameters and re-renders the charts.
   - From: Merchant browser
   - To: `emberApp` → `goodsVendorPortal_apiClient` → `continuumGoodsVendorPortalWeb` → `gpapiApi_unk_1d2b`
   - Protocol: DOM event then REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No insights data available | GPAPI returns an empty dataset; portal renders an empty state with a message | Merchant sees "No data available for the selected period" |
| GPAPI unavailable | Nginx returns 502/503; portal shows an error banner in the insights section | Charts cannot be rendered; merchant may retry |
| Large dataset slow response | GPAPI takes longer than expected to aggregate; portal may show a loading spinner for extended periods | Merchant waits; no automatic timeout at the portal layer (delegated to GPAPI SLA) |
| chart.js render error | A malformed data payload causes a chart rendering exception; the Ember component catches the error and renders an error state | The affected chart widget shows an error placeholder; other charts on the page are unaffected |

## Sequence Diagram

```
Merchant -> emberApp: Navigates to insights section
emberApp -> goodsVendorPortal_apiClient: Request insights data
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: GET /goods-gateway/insights[?date_from=X&date_to=Y]
continuumGoodsVendorPortalWeb -> gpapiApi_unk_1d2b: GET /insights (proxied)
gpapiApi_unk_1d2b --> continuumGoodsVendorPortalWeb: 200 OK { insights metrics payload }
continuumGoodsVendorPortalWeb --> goodsVendorPortal_apiClient: Proxy response
goodsVendorPortal_apiClient --> emberApp: Populate insights store
emberApp --> Merchant: Render chart.js charts + React visualization widgets
Merchant -> emberApp: Adjusts date filter
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: GET /goods-gateway/insights?date_from=X2&date_to=Y2
continuumGoodsVendorPortalWeb -> gpapiApi_unk_1d2b: GET /insights (proxied, updated params)
gpapiApi_unk_1d2b --> continuumGoodsVendorPortalWeb: 200 OK { updated metrics }
continuumGoodsVendorPortalWeb --> goodsVendorPortal_apiClient: Proxy response
goodsVendorPortal_apiClient --> emberApp: Update store
emberApp --> Merchant: Re-render charts with filtered data
```

## Related

- Architecture dynamic view: `dynamic-analytics-and-insights-reporting`
- Related flows: [Contract and Agreement Management](contract-and-agreement-management.md), [Deal and Promotion Creation](deal-and-promotion-creation.md)
