---
service: "mdi-dashboard-v2"
title: "Merchant Insights"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "merchant-insights"
flow_type: synchronous
trigger: "User navigates to the /merchantInsights view"
participants:
  - "continuumMarketingDealServiceDashboard"
  - "apiProxy"
  - "continuumMarketingDealService"
  - "salesForce"
architecture_ref: "dynamic-mdi-merchant-insights"
---

# Merchant Insights

## Summary

The merchant insights flow provides Marketing and Merchandising users with a unified view of merchant performance data. When a user navigates to the `/merchantInsights` route, the dashboard fetches deal performance data from the Marketing Deal Service and CRM account context from Salesforce, then merges and renders the combined insights view.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `GET /merchantInsights` in the dashboard
- **Frequency**: on-demand, per user interaction

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MDI Dashboard | Orchestrates data retrieval from multiple sources; renders merged insights | `continuumMarketingDealServiceDashboard` |
| API Proxy | Routes outbound HTTP calls to internal Continuum services | `apiProxy` |
| Marketing Deal Service | Provides deal performance data for the merchant | `continuumMarketingDealService` |
| Salesforce | Provides CRM account and relationship data for the merchant | `salesForce` |

## Steps

1. **Receives merchant insights request**: User navigates to `GET /merchantInsights` (optionally with a merchant identifier as query parameter).
   - From: `Browser (internal user)`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP

2. **Authenticates request**: itier-user-auth middleware validates the user session.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `itier-user-auth middleware`
   - Protocol: in-process

3. **Queries Marketing Deal Service for deal performance**: Dashboard fetches deal performance metrics for the merchant from the Marketing Deal Service via the API Proxy.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `apiProxy` -> `continuumMarketingDealService`
   - Protocol: REST / HTTP

4. **Returns deal performance data**: Marketing Deal Service responds with deal metrics for the merchant.
   - From: `continuumMarketingDealService`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP (JSON response)

5. **Queries Salesforce for CRM data**: Dashboard sends a request to Salesforce to retrieve CRM account and merchant relationship context.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `salesForce`
   - Protocol: REST / HTTP

6. **Returns CRM merchant data**: Salesforce responds with merchant account and relationship data.
   - From: `salesForce`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP (JSON response)

7. **Merges and renders insights view**: Dashboard merges deal performance data with CRM context and renders the merchant insights page via hogan.js templates.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `Browser (internal user)`
   - Protocol: HTTP (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Marketing Deal Service returns 5xx | Dashboard propagates error; page cannot render deal data | Error state shown for deal performance section |
| Salesforce unavailable or 5xx | Dashboard renders page without CRM data (non-blocking) | Merchant insights shown without Salesforce-sourced fields |
| Salesforce authentication failure | Dashboard logs error; omits CRM section | Page renders with warning that CRM data is unavailable |
| Authentication failure | itier-user-auth redirects to login | User redirected to Groupon SSO login |

## Sequence Diagram

```
User -> continuumMarketingDealServiceDashboard: GET /merchantInsights?merchant=<id>
continuumMarketingDealServiceDashboard -> apiProxy: GET /deals/merchant?id=<id>
apiProxy -> continuumMarketingDealService: GET /deals/merchant?id=<id>
continuumMarketingDealService --> apiProxy: 200 OK { deals: [...], metrics: {...} }
apiProxy --> continuumMarketingDealServiceDashboard: 200 OK { deals: [...], metrics: {...} }
continuumMarketingDealServiceDashboard -> salesForce: GET /account?merchantId=<id>
salesForce --> continuumMarketingDealServiceDashboard: 200 OK { account: {...} }
continuumMarketingDealServiceDashboard --> User: 200 OK (HTML merged insights view)
```

## Related

- Architecture dynamic view: `dynamic-mdi-merchant-insights`
- Related flows: [Deal Intelligence Search](deal-intelligence-search.md), [Deal Performance Tracking](deal-performance-tracking.md)
