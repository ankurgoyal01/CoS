---
service: "mdi-dashboard-v2"
title: "Deal Intelligence Search"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-intelligence-search"
flow_type: synchronous
trigger: "User submits a deal search query via the /browser route"
participants:
  - "continuumMarketingDealServiceDashboard"
  - "apiProxy"
  - "continuumMarketingDealService"
  - "continuumRelevanceApi"
architecture_ref: "dynamic-mdi-deal-intelligence-search"
---

# Deal Intelligence Search

## Summary

The deal intelligence search flow allows Marketing and Merchandising users to search and browse the Groupon deal catalog from within the dashboard. The user submits a search query via the `/browser` route; the dashboard forwards the query to the Marketing Deal Service (via the API Proxy), optionally augments results with relevance scores from the Relevance API, and renders the matching deals back to the user.

## Trigger

- **Type**: user-action
- **Source**: User submits a search query in the deal browser UI at `GET /browser`
- **Frequency**: on-demand, per user interaction

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MDI Dashboard | Receives user search request; orchestrates downstream calls; renders results | `continuumMarketingDealServiceDashboard` |
| API Proxy | Routes outbound HTTP calls from dashboard to internal Continuum services | `apiProxy` |
| Marketing Deal Service | Primary deal data source; executes the search query | `continuumMarketingDealService` |
| Relevance API | Provides relevance scores for deals in the result set | `continuumRelevanceApi` |

## Steps

1. **Receives search request**: User submits a search query (keywords, filters) to `GET /browser` on the dashboard.
   - From: `Browser (internal user)`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP

2. **Authenticates request**: itier-user-auth middleware validates the user session cookie.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `itier-user-auth middleware`
   - Protocol: in-process

3. **Forwards query to Marketing Deal Service**: Dashboard constructs a deal search request and sends it to the Marketing Deal Service via the API Proxy.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `apiProxy` -> `continuumMarketingDealService`
   - Protocol: REST / HTTP

4. **Returns deal result set**: Marketing Deal Service executes the search and returns matching deal records.
   - From: `continuumMarketingDealService`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP (JSON response)

5. **Queries relevance scores**: Dashboard sends deal IDs to the Relevance API to retrieve relevance scores for result ranking.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `continuumRelevanceApi` (via `apiProxy`)
   - Protocol: REST / HTTP

6. **Receives relevance scores**: Relevance API returns scores for the queried deal IDs.
   - From: `continuumRelevanceApi`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP (JSON response)

7. **Merges and renders results**: Dashboard merges deal records with relevance scores and renders the result page via hogan.js templates.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `Browser (internal user)`
   - Protocol: HTTP (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Marketing Deal Service returns 5xx | Dashboard propagates error to user | Error page or empty results shown |
| Marketing Deal Service timeout | HTTP client timeout; error propagated | User sees error; retry available |
| Relevance API unavailable | Dashboard renders results without relevance scores | Deal list shown without ranking signal |
| Authentication failure | itier-user-auth redirects to login | User redirected to Groupon SSO login |

## Sequence Diagram

```
User -> continuumMarketingDealServiceDashboard: GET /browser?q=<query>
continuumMarketingDealServiceDashboard -> apiProxy: GET /deals/search?q=<query>
apiProxy -> continuumMarketingDealService: GET /deals/search?q=<query>
continuumMarketingDealService --> apiProxy: 200 OK { deals: [...] }
apiProxy --> continuumMarketingDealServiceDashboard: 200 OK { deals: [...] }
continuumMarketingDealServiceDashboard -> continuumRelevanceApi: GET /relevance?ids=<dealIds>
continuumRelevanceApi --> continuumMarketingDealServiceDashboard: 200 OK { scores: {...} }
continuumMarketingDealServiceDashboard --> User: 200 OK (HTML rendered results)
```

## Related

- Architecture dynamic view: `dynamic-mdi-deal-intelligence-search`
- Related flows: [Deal Performance Tracking](deal-performance-tracking.md), [Deal Cluster Analytics](deal-cluster-analytics.md)
