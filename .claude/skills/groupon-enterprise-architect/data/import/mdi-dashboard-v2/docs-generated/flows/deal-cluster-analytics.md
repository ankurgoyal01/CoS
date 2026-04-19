---
service: "mdi-dashboard-v2"
title: "Deal Cluster Analytics"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-cluster-analytics"
flow_type: synchronous
trigger: "User navigates to the /clusters view"
participants:
  - "continuumMarketingDealServiceDashboard"
  - "apiProxy"
architecture_ref: "dynamic-mdi-deal-cluster-analytics"
---

# Deal Cluster Analytics

## Summary

The deal cluster analytics flow delivers deal grouping and clustering analysis to Marketing and Merchandising users. When a user navigates to the `/clusters` route, the dashboard queries the Deals Cluster API (via the API Proxy) to retrieve pre-computed or on-demand cluster data, then renders the analytics view showing how deals are grouped by category, merchant, or other dimensions.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `GET /clusters` in the dashboard
- **Frequency**: on-demand, per user interaction

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MDI Dashboard | Receives user navigation; queries cluster data; renders analytics view | `continuumMarketingDealServiceDashboard` |
| API Proxy | Routes outbound HTTP calls to internal Continuum services | `apiProxy` |
| Deals Cluster API | Supplies deal clustering and grouping analytics data | > No Structurizr ID confirmed in inventory |

## Steps

1. **Receives cluster analytics request**: User navigates to `GET /clusters` on the dashboard.
   - From: `Browser (internal user)`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP

2. **Authenticates request**: itier-user-auth middleware validates the user session.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `itier-user-auth middleware`
   - Protocol: in-process

3. **Queries Deals Cluster API**: Dashboard sends a cluster data request to the Deals Cluster API via the API Proxy.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `apiProxy` -> Deals Cluster API
   - Protocol: REST / HTTP

4. **Returns cluster data**: Deals Cluster API responds with deal cluster groupings and analytics payload.
   - From: Deals Cluster API
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP (JSON response)

5. **Renders analytics view**: Dashboard processes the cluster data and renders the analytics view via hogan.js templates.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `Browser (internal user)`
   - Protocol: HTTP (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deals Cluster API returns 5xx | Dashboard propagates error to user | Error message displayed on /clusters page |
| Deals Cluster API timeout | HTTP client timeout; error returned | User sees error; retry available via page reload |
| Authentication failure | itier-user-auth redirects to login | User redirected to Groupon SSO login |

## Sequence Diagram

```
User -> continuumMarketingDealServiceDashboard: GET /clusters
continuumMarketingDealServiceDashboard -> apiProxy: GET /clusters
apiProxy -> DealsClusterAPI: GET /clusters
DealsClusterAPI --> apiProxy: 200 OK { clusters: [...] }
apiProxy --> continuumMarketingDealServiceDashboard: 200 OK { clusters: [...] }
continuumMarketingDealServiceDashboard --> User: 200 OK (HTML analytics view)
```

## Related

- Architecture dynamic view: `dynamic-mdi-deal-cluster-analytics`
- Related flows: [Deal Intelligence Search](deal-intelligence-search.md), [Deal Performance Tracking](deal-performance-tracking.md)
