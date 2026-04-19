---
service: "next-pwa-app"
title: "Consumer Browse and Search Flow"
generated: "2026-03-03"
type: flow
flow_name: "consumer-browse-and-search"
flow_type: synchronous
trigger: "User navigates to a browse or search page"
participants:
  - "consumer"
  - "mbnxtWebsite"
  - "web_routing"
  - "web_feature_modules"
  - "web_graphql_client"
  - "mbnxtGraphQL"
  - "continuumRelevanceApi"
  - "booster"
  - "continuumDealManagementApi"
architecture_ref: "dynamic-consumer-browse-and-checkout"
---

# Consumer Browse and Search Flow

## Summary

When a consumer navigates to a browse page (e.g., `/local`, `/goods`, `/travel`) or performs a search, the Next.js server renders the page using data fetched from the MBNXT GraphQL API. The GraphQL layer orchestrates calls to the Relevance API (RAPI) for ranked deal feeds, Booster for boosted feed payloads, and the Deal Management API for merchandising metadata. The rendered HTML is returned to the browser, where Apollo Client hydrates and manages subsequent client-side navigation.

## Trigger

- **Type**: user-action
- **Source**: Consumer navigates via URL or client-side navigation to a browse/search page
- **Frequency**: On demand (high-traffic, primary user journey)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer | Initiates page request via browser | `consumer` |
| MBNXT Web | Receives HTTP request, runs middleware, renders page | `mbnxtWebsite` |
| Web Routing & Pages | Matches route, invokes getServerSideProps or RSC render | `web_routing` |
| Web Feature Modules | Browse/search feature module composing UI and data needs | `web_feature_modules` |
| Web GraphQL Client | Executes GraphQL queries to fetch deal feed data | `web_graphql_client` |
| MBNXT GraphQL | Resolves deal-feed queries, fans out to backend services | `mbnxtGraphQL` |
| Relevance API (RAPI) | Returns ranked deal results based on query, location, filters | `continuumRelevanceApi` |
| Booster | Returns boosted/ranked feed payloads | `booster` |
| Deal Management API | Provides deal metadata, categories, and merchandising info | `continuumDealManagementApi` |

## Steps

1. **Browser Request**: Consumer navigates to a browse or search URL (e.g., `/local/deals/things-to-do`)
   - From: `consumer`
   - To: `mbnxtWebsite`
   - Protocol: HTTPS

2. **Middleware Processing**: The middleware chain processes the request (locale detection, authorization, template detection, redirects, rewrites)
   - From: `mbnxtWebsite` (middleware)
   - To: `web_routing`
   - Protocol: Direct (Next.js internal)

3. **Route Resolution**: Next.js resolves the route to the appropriate page component and triggers server-side data fetching (getServerSideProps or RSC data loading)
   - From: `web_routing`
   - To: `web_feature_modules`
   - Protocol: Direct

4. **GraphQL Query**: The browse/search feature module issues GraphQL queries for deal feed data
   - From: `web_feature_modules` via `web_graphql_client`
   - To: `mbnxtGraphQL`
   - Protocol: HTTP POST to `/api/graphql`

5. **Relevance API Call**: The GraphQL resolver calls the Relevance API to fetch ranked deal results
   - From: `mbnxtGraphQL`
   - To: `continuumRelevanceApi`
   - Protocol: REST/HTTPS

6. **Booster Feed Call**: The GraphQL resolver calls Booster for boosted feed payloads (if applicable)
   - From: `mbnxtGraphQL`
   - To: `booster`
   - Protocol: REST/HTTPS

7. **Deal Metadata Enrichment**: The GraphQL resolver calls the Deal Management API to enrich deal cards with metadata
   - From: `mbnxtGraphQL`
   - To: `continuumDealManagementApi`
   - Protocol: REST/HTTPS

8. **Response Assembly**: The GraphQL layer aggregates responses and returns the deal feed data to the web client
   - From: `mbnxtGraphQL`
   - To: `web_graphql_client`
   - Protocol: GraphQL response (JSON)

9. **Page Render**: The feature module renders the browse page with deal cards, filters, and pagination
   - From: `web_feature_modules`
   - To: `web_routing`
   - Protocol: React render (SSR)

10. **HTML Response**: The fully rendered HTML page is sent to the consumer's browser
    - From: `mbnxtWebsite`
    - To: `consumer`
    - Protocol: HTTPS (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Relevance API timeout | GraphQL resolver returns partial/empty results | Browse page renders with empty state or cached data |
| Booster API failure | Fallback to non-boosted feed from RAPI | Page renders without boosted content |
| GraphQL query error | Error boundary catches and renders error UI | Consumer sees error state with retry option |
| Middleware redirect loop | Redirect loop detection in middleware chain | 500 error returned |

## Sequence Diagram

```
Consumer -> MBNXT Web: GET /local/deals/things-to-do
MBNXT Web -> Middleware: Process request (locale, auth, rewrites)
Middleware -> Web Routing: Resolved route
Web Routing -> Web Feature Modules: Invoke browse page data loading
Web Feature Modules -> Web GraphQL Client: Execute dealFeed query
Web GraphQL Client -> MBNXT GraphQL: POST /api/graphql
MBNXT GraphQL -> Relevance API: GET ranked deal results
Relevance API --> MBNXT GraphQL: Deal feed response
MBNXT GraphQL -> Booster: GET boosted feed
Booster --> MBNXT GraphQL: Boosted feed response
MBNXT GraphQL -> Deal Management API: GET deal metadata
Deal Management API --> MBNXT GraphQL: Deal metadata
MBNXT GraphQL --> Web GraphQL Client: GraphQL response
Web Feature Modules -> Web Routing: Rendered page HTML
MBNXT Web --> Consumer: HTML response
```

## Related

- Architecture dynamic view: `dynamic-consumer-browse-and-checkout`
- Related flows: [Deal Page View](deal-page-view.md), [Checkout and Order](checkout-and-order.md)
