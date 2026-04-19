---
service: "mdi-dashboard-v2"
title: "Search Taxonomy Discovery"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "search-taxonomy-discovery"
flow_type: synchronous
trigger: "User types in a taxonomy, city, or location search field"
participants:
  - "continuumMarketingDealServiceDashboard"
  - "apiProxy"
  - "continuumTaxonomyService"
architecture_ref: "dynamic-mdi-search-taxonomy-discovery"
---

# Search Taxonomy Discovery

## Summary

The search taxonomy discovery flow powers autocomplete and category browsing in the dashboard by querying the Taxonomy Service for matching taxonomy categories, cities, and locations. When a user types in a search field, the dashboard forwards the query to the Taxonomy Service (via the API Proxy) and returns matching results to populate the UI. This flow is used as a support mechanism across multiple dashboard views, particularly the deal browser and feed builder.

## Trigger

- **Type**: user-action
- **Source**: User enters a search term in a taxonomy/city/location input field; request made to `GET /search/*`
- **Frequency**: on-demand, per keystroke or form submission

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MDI Dashboard | Receives search request; forwards query to Taxonomy Service; returns results | `continuumMarketingDealServiceDashboard` |
| API Proxy | Routes outbound HTTP calls to internal Continuum services | `apiProxy` |
| Taxonomy Service | Supplies taxonomy categories, cities, and location data | `continuumTaxonomyService` |

## Steps

1. **Receives taxonomy search request**: User input triggers a `GET /search/*` request with a query string.
   - From: `Browser (internal user)`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP

2. **Authenticates request**: itier-user-auth middleware validates user session.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `itier-user-auth middleware`
   - Protocol: in-process

3. **Forwards query to Taxonomy Service**: Dashboard constructs a taxonomy/city/location search request and sends it to the Taxonomy Service via the API Proxy.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `apiProxy` -> `continuumTaxonomyService`
   - Protocol: REST / HTTP

4. **Returns matching results**: Taxonomy Service responds with matching taxonomy nodes, city names, or location records.
   - From: `continuumTaxonomyService`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP (JSON response)

5. **Returns results to browser**: Dashboard forwards the search results to the browser for autocomplete rendering.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `Browser (internal user)`
   - Protocol: HTTP (JSON response for AJAX autocomplete or HTML for full page)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Taxonomy Service returns 5xx | Dashboard propagates error | Search field shows no suggestions; user can type manually |
| Taxonomy Service timeout | HTTP client timeout | No autocomplete results returned; user can proceed without autocomplete |
| Authentication failure | itier-user-auth redirects to login | User redirected to Groupon SSO login |

## Sequence Diagram

```
User -> continuumMarketingDealServiceDashboard: GET /search/taxonomy?q=<term>
continuumMarketingDealServiceDashboard -> apiProxy: GET /taxonomy/search?q=<term>
apiProxy -> continuumTaxonomyService: GET /search?q=<term>
continuumTaxonomyService --> apiProxy: 200 OK { results: [...] }
apiProxy --> continuumMarketingDealServiceDashboard: 200 OK { results: [...] }
continuumMarketingDealServiceDashboard --> User: 200 OK (JSON autocomplete results)
```

## Related

- Architecture dynamic view: `dynamic-mdi-search-taxonomy-discovery`
- Related flows: [Deal Intelligence Search](deal-intelligence-search.md), [Feed Creation and Generation](feed-creation-generation.md)
