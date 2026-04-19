---
service: "mygroupons"
title: "Render Account Details Editor"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "render-account-details-editor"
flow_type: synchronous
trigger: "User views /mygroupons/account/details"
participants:
  - "browser"
  - "continuumMygrouponsService"
  - "apiProxy"
  - "continuumUsersService"
architecture_ref: "dynamic-mygroupons-account-details"
---

# Render Account Details Editor

## Summary

This flow renders the account details editing page at `/mygroupons/account/details`. The service fetches the authenticated user's account information from Users Service and presents an editable form for profile details (name, email, password, notification preferences). This page is accessible from the My Groupons navigation and provides account self-service without leaving the post-purchase context.

## Trigger

- **Type**: user-action
- **Source**: Browser GET request to `/mygroupons/account/details`
- **Frequency**: On demand — triggered when a customer navigates to their account details page

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Requests account details page; views and edits account information | — |
| My Groupons Service | Route handler, user data fetch, SSR | `continuumMygrouponsService` |
| API Proxy | Routes outbound downstream HTTP calls | `apiProxy` |
| Users Service | Provides authenticated user's account details; processes account updates | `continuumUsersService` |

## Steps

1. **Receives account details request**: Browser sends `GET /mygroupons/account/details` with session cookie.
   - From: `browser`
   - To: `continuumMygrouponsService`
   - Protocol: REST/HTTP

2. **Validates session**: keldor validates session and extracts user identity from the session token.
   - From: `continuumMygrouponsService`
   - To: `continuumUsersService` (via `apiProxy`)
   - Protocol: REST/HTTP

3. **Fetches account details**: Retrieves the user's full account profile from Users Service, including name, email, and preference settings.
   - From: `continuumMygrouponsService`
   - To: `continuumUsersService` (via `apiProxy`)
   - Protocol: REST/HTTP

4. **Fetches page layout**: Requests global page layout from Layout Service.
   - From: `continuumMygrouponsService`
   - To: Layout Service (via `apiProxy`)
   - Protocol: REST/HTTP

5. **Renders account details editor**: Assembles user profile data and layout; renders the account editing form using Preact and Mustache with pre-populated field values.
   - From: `continuumMygrouponsService` (internal)
   - To: `continuumMygrouponsService` (internal)
   - Protocol: direct

6. **Returns account page**: Streams the rendered HTML to the browser.
   - From: `continuumMygrouponsService`
   - To: `browser`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session invalid | keldor redirects to login | Redirect to sign-in page |
| Users Service unavailable | Critical failure | Error page rendered |
| Account data fetch fails | Critical failure | Error page rendered |

## Sequence Diagram

```
Browser -> MyGrouponsService: GET /mygroupons/account/details
MyGrouponsService -> APIProxy: validate session
APIProxy -> UsersService: resolve + validate user
UsersService --> APIProxy: session valid + user identity
APIProxy --> MyGrouponsService: user identity
MyGrouponsService -> APIProxy: fetch account details (parallel)
MyGrouponsService -> APIProxy: fetch page layout (parallel)
APIProxy -> UsersService: get user profile
UsersService --> APIProxy: account details
APIProxy -> LayoutService: get page layout
LayoutService --> APIProxy: layout HTML
APIProxy --> MyGrouponsService: account details + layout
MyGrouponsService -> MyGrouponsService: SSR render (Preact + Mustache)
MyGrouponsService --> Browser: account details editor HTML
```

## Related

- Architecture dynamic view: `dynamic-mygroupons-account-details`
- Related flows: [Render My Groupons Page](render-mygroupons-page.md), [Manage Groupon Bucks Balance](manage-groupon-bucks-balance.md)
