---
service: "next-pwa-app"
title: "Deal Page View Flow"
generated: "2026-03-03"
type: flow
flow_name: "deal-page-view"
flow_type: synchronous
trigger: "User clicks a deal link or navigates to a deal URL"
participants:
  - "consumer"
  - "mbnxtWebsite"
  - "web_routing"
  - "web_feature_modules"
  - "web_graphql_client"
  - "mbnxtGraphQL"
  - "continuumApiLazloService"
  - "continuumUgcService"
  - "continuumDealManagementApi"
architecture_ref: "dynamic-consumer-browse-and-checkout"
---

# Deal Page View Flow

## Summary

When a consumer navigates to a deal page (`/deals/:slug`), the Next.js server renders the page by fetching deal details through the MBNXT GraphQL API. The GraphQL layer calls the API Proxy (Lazlo) for comprehensive deal data (pricing, options, availability), the UGC Service for ratings and reviews, and the Deal Management API for merchandising metadata. The rendered page is returned as HTML with Apollo Client state for subsequent client-side interactions.

## Trigger

- **Type**: user-action
- **Source**: Consumer clicks a deal card from browse results, search, or direct URL navigation
- **Frequency**: On demand (high-traffic, primary conversion funnel)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer | Initiates deal page request | `consumer` |
| MBNXT Web | Receives request, runs middleware, renders page | `mbnxtWebsite` |
| Web Routing & Pages | Matches deal route, invokes data fetching | `web_routing` |
| Web Feature Modules | Deal feature module handling page composition | `web_feature_modules` |
| Web GraphQL Client | Executes GraphQL queries for deal data | `web_graphql_client` |
| MBNXT GraphQL | Resolves deal queries, fans out to backend services | `mbnxtGraphQL` |
| API Proxy (Lazlo) | Primary deal data source (pricing, options, checkout details) | `continuumApiLazloService` |
| UGC Service | Ratings, reviews, and user-generated content | `continuumUgcService` |
| Deal Management API | Merchandising metadata, deal attributes | `continuumDealManagementApi` |

## Steps

1. **Browser Request**: Consumer navigates to a deal URL (e.g., `/deals/spa-day-relaxation`)
   - From: `consumer`
   - To: `mbnxtWebsite`
   - Protocol: HTTPS

2. **Middleware Processing**: Request passes through middleware chain for locale, auth, deal hybrid redirect logic
   - From: `mbnxtWebsite` (middleware)
   - To: `web_routing`
   - Protocol: Direct

3. **Route Resolution**: Next.js resolves the deal page route and invokes data fetching
   - From: `web_routing`
   - To: `web_feature_modules`
   - Protocol: Direct

4. **GraphQL Query - Deal Data**: Deal feature module queries for deal details
   - From: `web_feature_modules` via `web_graphql_client`
   - To: `mbnxtGraphQL`
   - Protocol: HTTP POST to `/api/graphql`

5. **API Proxy Call**: GraphQL resolver fetches deal data from API Proxy (Lazlo)
   - From: `mbnxtGraphQL`
   - To: `continuumApiLazloService`
   - Protocol: REST/HTTPS

6. **UGC Call**: GraphQL resolver fetches ratings and reviews
   - From: `mbnxtGraphQL`
   - To: `continuumUgcService`
   - Protocol: REST/HTTPS

7. **Deal Metadata Call**: GraphQL resolver fetches merchandising metadata
   - From: `mbnxtGraphQL`
   - To: `continuumDealManagementApi`
   - Protocol: REST/HTTPS

8. **Response Assembly**: GraphQL aggregates deal data and returns to the web client
   - From: `mbnxtGraphQL`
   - To: `web_graphql_client`
   - Protocol: GraphQL response (JSON)

9. **Page Render**: Deal page is rendered with all details, pricing, images, reviews, and purchase options
   - From: `web_feature_modules`
   - To: `web_routing`
   - Protocol: React render (SSR)

10. **HTML Response**: Rendered deal page is sent to the consumer
    - From: `mbnxtWebsite`
    - To: `consumer`
    - Protocol: HTTPS (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| API Proxy (Lazlo) timeout | GraphQL error returned | Deal page shows error state |
| Deal not found | 404 handling in getServerSideProps | Redirect to 404 page |
| UGC Service failure | Partial data returned | Deal page renders without reviews section |
| Deal Management API failure | Partial data returned | Deal page renders with limited metadata |

## Sequence Diagram

```
Consumer -> MBNXT Web: GET /deals/spa-day-relaxation
MBNXT Web -> Middleware: Process request
Middleware -> Web Routing: Resolved deal route
Web Routing -> Web Feature Modules: Invoke deal page data loading
Web Feature Modules -> Web GraphQL Client: Execute deal query
Web GraphQL Client -> MBNXT GraphQL: POST /api/graphql
MBNXT GraphQL -> API Proxy (Lazlo): GET deal details
API Proxy (Lazlo) --> MBNXT GraphQL: Deal data (pricing, options)
MBNXT GraphQL -> UGC Service: GET ratings and reviews
UGC Service --> MBNXT GraphQL: Review data
MBNXT GraphQL -> Deal Management API: GET deal metadata
Deal Management API --> MBNXT GraphQL: Merchandising metadata
MBNXT GraphQL --> Web GraphQL Client: GraphQL response
Web Feature Modules -> Web Routing: Rendered deal page HTML
MBNXT Web --> Consumer: HTML response
```

## Related

- Architecture dynamic view: `dynamic-consumer-browse-and-checkout`
- Related flows: [Consumer Browse and Search](consumer-browse-and-search.md), [Checkout and Order](checkout-and-order.md)
