---
service: "bling"
title: "User Authentication"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "user-authentication"
flow_type: synchronous
trigger: "User accesses bling in the browser for the first time or when an existing session expires"
participants:
  - "continuumBlingWebApp"
  - "blingNginx"
architecture_ref: "dynamic-finance-operations-flow"
---

# User Authentication

## Summary

This flow describes how a finance or accounting staff member authenticates to the bling application using Okta SSO via the Hybrid Boundary OAuth2 proxy. When a user accesses the SPA without a valid session, the Nginx proxy routes the OAuth2 flow through the Hybrid Boundary, which handles the Okta redirect and token exchange. On successful authentication, an Okta bearer token is issued and attached to all subsequent API requests. bling itself contains no authentication logic — all auth is delegated to the Hybrid Boundary and Okta.

## Trigger

- **Type**: user-action
- **Source**: Finance or accounting staff member navigates to the bling URL in their browser; no valid session exists or the session has expired
- **Frequency**: Per login session; typically once per working day per user

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Finance/Accounting Staff | Navigates to bling; completes Okta login | — |
| bling Web Application | Detects unauthenticated state; handles OAuth callback; stores session token | `continuumBlingWebApp` |
| bling Nginx | Enforces authentication at the proxy layer; routes OAuth callbacks | `blingNginx` |
| Hybrid Boundary | OAuth2 proxy; manages Okta redirect and token exchange | — |
| Okta | Identity provider; presents login UI; issues access token | — |

## Steps

1. **User navigates to bling**: Finance staff member opens the bling URL in their browser.
   - From: Browser (user)
   - To: `blingNginx`
   - Protocol: HTTPS GET

2. **Nginx detects unauthenticated session**: `blingNginx` determines no valid OAuth2 session exists (no bearer token in request).
   - From: `blingNginx` (internal check)
   - To: `blingNginx`
   - Protocol: Internal Nginx auth check

3. **Nginx redirects to Hybrid Boundary**: `blingNginx` issues an OAuth2 authorization redirect to the Hybrid Boundary at the URL configured in `HYBRID_BOUNDARY_URL`.
   - From: `blingNginx`
   - To: Hybrid Boundary
   - Protocol: HTTPS redirect (302)

4. **Hybrid Boundary redirects to Okta login**: Hybrid Boundary constructs the Okta authorization URL using `OKTA_CLIENT_ID` and `OKTA_ISSUER` and redirects the browser to Okta.
   - From: Hybrid Boundary
   - To: Okta
   - Protocol: HTTPS redirect (OAuth2 authorization code flow)

5. **Staff completes Okta login**: The user enters their Groupon credentials in the Okta login UI; Okta authenticates the user.
   - From: Browser (user)
   - To: Okta
   - Protocol: HTTPS (browser-based)

6. **Okta issues authorization code**: Okta redirects back to the Hybrid Boundary with an authorization code.
   - From: Okta
   - To: Hybrid Boundary
   - Protocol: HTTPS redirect with `?code=<auth_code>`

7. **Hybrid Boundary exchanges code for token**: Hybrid Boundary exchanges the authorization code for an Okta access token via the token endpoint.
   - From: Hybrid Boundary
   - To: Okta token endpoint
   - Protocol: HTTPS POST (OAuth2 token exchange)

8. **Hybrid Boundary sets session and redirects to bling**: Hybrid Boundary establishes a session with the access token and redirects the browser back to `blingNginx` with the token.
   - From: Hybrid Boundary
   - To: `blingNginx`
   - Protocol: HTTPS redirect with session cookie or bearer token

9. **Nginx serves bling SPA**: With a valid token present, `blingNginx` serves the compiled SPA static assets to the browser.
   - From: `blingNginx`
   - To: Browser (user)
   - Protocol: HTTPS

10. **SPA loads with authenticated session**: `continuumBlingWebApp` initialises with the Okta bearer token available; subsequent API requests include `Authorization: Bearer <okta_token>`.
    - From: `continuumBlingWebApp`
    - To: Browser (user)
    - Protocol: Browser rendering

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Okta login fails (wrong credentials) | Okta shows error; no redirect to bling | User remains on Okta login page; must retry credentials |
| Hybrid Boundary unreachable | Nginx returns 502; browser shows error | User cannot access bling; incident if prolonged |
| `OKTA_CLIENT_ID` or `OKTA_ISSUER` misconfigured | OAuth2 flow fails; Okta returns error response | All users blocked from accessing bling; requires configuration fix and restart |
| Session token expires mid-session | Accounting Service or File Sharing Service returns 401 | Browser is redirected through authentication flow again; in-progress work may be lost |
| User not in Okta bling application group | Okta denies authorization | User receives Okta access denied error; access provisioning required |

## Sequence Diagram

```
FinanceStaff -> blingNginx: GET / (no session)
blingNginx -> HybridBoundary: 302 Redirect to OAuth2 authorize (HYBRID_BOUNDARY_URL)
HybridBoundary -> Okta: 302 Redirect to Okta login (OKTA_ISSUER, OKTA_CLIENT_ID)
FinanceStaff -> Okta: Submit credentials
Okta --> HybridBoundary: 302 Redirect with auth code
HybridBoundary -> Okta: POST /token (code exchange)
Okta --> HybridBoundary: 200 OK, access_token
HybridBoundary --> blingNginx: 302 Redirect with session/token
blingNginx --> FinanceStaff: Serve bling SPA (200 OK)
continuumBlingWebApp --> FinanceStaff: Initialise authenticated SPA session
```

## Related

- Architecture dynamic view: `dynamic-finance-operations-flow`
- Related flows: [Finance Data Viewing](finance-data-viewing.md), [Invoice Approval](invoice-approval.md), [Paysource File Upload](paysource-file-upload.md), [Contract Management](contract-management.md), [Search and Batch](search-and-batch.md)
