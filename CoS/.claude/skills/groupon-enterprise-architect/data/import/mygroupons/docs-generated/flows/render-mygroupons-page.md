---
service: "mygroupons"
title: "Render My Groupons Page"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "render-mygroupons-page"
flow_type: synchronous
trigger: "User navigates to /mygroupons"
participants:
  - "browser"
  - "continuumMygrouponsService"
  - "apiProxy"
  - "continuumUsersService"
  - "continuumOrdersService"
  - "continuumDealCatalogService"
  - "continuumRelevanceApi"
  - "gims"
architecture_ref: "dynamic-mygroupons-render-page"
---

# Render My Groupons Page

## Summary

This flow handles the main post-purchase deal list page. When an authenticated user navigates to `/mygroupons`, the service orchestrates parallel calls to the Orders Service, Deal Catalog, Relevance API, and GIMS to compose a complete view of the user's purchased deals, then renders the page server-side using Preact and streams the HTML response to the browser.

## Trigger

- **Type**: user-action
- **Source**: Browser GET request to `/mygroupons`
- **Frequency**: On demand — every time a customer visits their My Groupons page

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates page request; receives rendered HTML | — |
| My Groupons Service | Route handler + request orchestration + SSR | `continuumMygrouponsService` |
| API Proxy | Routes outbound downstream HTTP calls | `apiProxy` |
| Users Service | Validates session and resolves user identity | `continuumUsersService` |
| Orders Service | Returns paginated list of customer orders and vouchers | `continuumOrdersService` |
| Deal Catalog Service | Returns deal metadata for each order (title, images, merchant) | `continuumDealCatalogService` |
| Relevance API | Returns personalised deal recommendations | `continuumRelevanceApi` |
| GIMS | Returns geographic and merchant display data | `gims` |

## Steps

1. **Receives page request**: Browser sends `GET /mygroupons` with session cookie.
   - From: `browser`
   - To: `continuumMygrouponsService`
   - Protocol: REST/HTTP

2. **Validates session**: keldor middleware extracts and validates the session token; resolves user identity via Users Service.
   - From: `continuumMygrouponsService`
   - To: `continuumUsersService` (via `apiProxy`)
   - Protocol: REST/HTTP

3. **Fetches orders**: Calls Orders Service to retrieve the customer's paginated order and voucher list.
   - From: `continuumMygrouponsService`
   - To: `continuumOrdersService` (via `apiProxy`)
   - Protocol: REST/HTTP

4. **Fan-out enrichment**: In parallel, fetches deal metadata from Deal Catalog, personalised recommendations from Relevance API, and merchant/geographic data from GIMS using `async` parallel orchestration.
   - From: `continuumMygrouponsService`
   - To: `continuumDealCatalogService`, `continuumRelevanceApi`, `gims` (via `apiProxy`)
   - Protocol: REST/HTTP

5. **Fetches page layout**: Requests global page layout (header, footer, nav) from Layout Service.
   - From: `continuumMygrouponsService`
   - To: Layout Service (via `apiProxy`)
   - Protocol: REST/HTTP

6. **Renders page**: Merges all data, renders Preact components server-side, injects into Mustache shell template, and evaluates feature flags (e.g., `load_order`, `ai_chatbot`) to toggle sections.
   - From: `continuumMygrouponsService` (internal)
   - To: `continuumMygrouponsService` (internal)
   - Protocol: direct

7. **Streams HTML response**: Returns fully rendered HTML page to the browser.
   - From: `continuumMygrouponsService`
   - To: `browser`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session invalid or expired | keldor redirects to login | User is redirected to sign-in page |
| Orders Service unavailable | Propagates as critical error | Error page rendered |
| Deal Catalog unavailable | Propagates as critical error | Error page rendered (deal metadata required) |
| Relevance API unavailable | Non-critical; section skipped | Page renders without recommendations section |
| GIMS unavailable | Non-critical; section skipped | Page renders without merchant geo data |

## Sequence Diagram

```
Browser -> MyGrouponsService: GET /mygroupons (session cookie)
MyGrouponsService -> APIProxy: validate session
APIProxy -> UsersService: resolve user identity
UsersService --> APIProxy: user data
APIProxy --> MyGrouponsService: user data
MyGrouponsService -> APIProxy: fetch orders
APIProxy -> OrdersService: get customer orders
OrdersService --> APIProxy: orders + vouchers list
APIProxy --> MyGrouponsService: orders + vouchers list
MyGrouponsService -> APIProxy: fetch deal metadata (parallel)
MyGrouponsService -> APIProxy: fetch recommendations (parallel)
MyGrouponsService -> APIProxy: fetch merchant/geo data (parallel)
APIProxy --> MyGrouponsService: deal metadata
APIProxy --> MyGrouponsService: recommendations
APIProxy --> MyGrouponsService: merchant/geo data
MyGrouponsService -> MyGrouponsService: SSR render (Preact + Mustache + feature flags)
MyGrouponsService --> Browser: HTML page
```

## Related

- Architecture dynamic view: `dynamic-mygroupons-render-page`
- Related flows: [Request Voucher PDF Download](request-voucher-pdf-download.md), [Manage Groupon Bucks Balance](manage-groupon-bucks-balance.md)
