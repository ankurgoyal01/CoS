---
service: "mygroupons"
title: "Manage Groupon Bucks Balance"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "manage-groupon-bucks-balance"
flow_type: synchronous
trigger: "User views /mygroupons/my-bucks"
participants:
  - "browser"
  - "continuumMygrouponsService"
  - "apiProxy"
  - "continuumUsersService"
  - "continuumOrdersService"
architecture_ref: "dynamic-mygroupons-groupon-bucks"
---

# Manage Groupon Bucks Balance

## Summary

This flow renders the Groupon Bucks page, which displays the authenticated user's current Bucks balance and transaction history (credits and debits). Groupon Bucks are a loyalty currency earned from returns, refunds, and promotions. The service fetches the balance and history from the Orders Service and renders the page for the user.

## Trigger

- **Type**: user-action
- **Source**: Browser GET request to `/mygroupons/my-bucks`
- **Frequency**: On demand — triggered when a customer views their Groupon Bucks balance

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Requests Bucks page; views balance and history | — |
| My Groupons Service | Route handler, data fetch, SSR | `continuumMygrouponsService` |
| API Proxy | Routes outbound downstream HTTP calls | `apiProxy` |
| Users Service | Validates session and resolves user identity | `continuumUsersService` |
| Orders Service | Returns Groupon Bucks balance and transaction history for the user | `continuumOrdersService` |

## Steps

1. **Receives Bucks page request**: Browser sends `GET /mygroupons/my-bucks` with session cookie.
   - From: `browser`
   - To: `continuumMygrouponsService`
   - Protocol: REST/HTTP

2. **Validates session**: keldor validates session; Users Service resolves user identity.
   - From: `continuumMygrouponsService`
   - To: `continuumUsersService` (via `apiProxy`)
   - Protocol: REST/HTTP

3. **Fetches Bucks balance and history**: Calls Orders Service to retrieve the current Groupon Bucks balance and the list of credit/debit transactions.
   - From: `continuumMygrouponsService`
   - To: `continuumOrdersService` (via `apiProxy`)
   - Protocol: REST/HTTP

4. **Fetches page layout**: Requests global page layout from Layout Service.
   - From: `continuumMygrouponsService`
   - To: Layout Service (via `apiProxy`)
   - Protocol: REST/HTTP

5. **Renders Bucks page**: Assembles balance, transaction history, and layout; renders the page using Preact and Mustache showing current balance prominently and a chronological transaction list.
   - From: `continuumMygrouponsService` (internal)
   - To: `continuumMygrouponsService` (internal)
   - Protocol: direct

6. **Returns Bucks page**: Streams the rendered HTML to the browser.
   - From: `continuumMygrouponsService`
   - To: `browser`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session invalid | keldor redirects to login | Redirect to sign-in page |
| Orders Service unavailable | Critical failure | Error page rendered |
| Bucks balance not available | Returns zero balance with empty history | Page renders showing 0 Bucks balance |

## Sequence Diagram

```
Browser -> MyGrouponsService: GET /mygroupons/my-bucks
MyGrouponsService -> APIProxy: validate session
APIProxy -> UsersService: resolve user
UsersService --> APIProxy: user data
APIProxy --> MyGrouponsService: user data
MyGrouponsService -> APIProxy: fetch Bucks balance + history
APIProxy -> OrdersService: get Groupon Bucks for user
OrdersService --> APIProxy: balance + transaction history
APIProxy --> MyGrouponsService: balance + transaction history
MyGrouponsService -> APIProxy: fetch page layout
APIProxy --> MyGrouponsService: layout HTML
MyGrouponsService -> MyGrouponsService: SSR render (Preact + Mustache)
MyGrouponsService --> Browser: Groupon Bucks page HTML
```

## Related

- Architecture dynamic view: `dynamic-mygroupons-groupon-bucks`
- Related flows: [Render My Groupons Page](render-mygroupons-page.md), [Render Account Details Editor](render-account-details-editor.md)
