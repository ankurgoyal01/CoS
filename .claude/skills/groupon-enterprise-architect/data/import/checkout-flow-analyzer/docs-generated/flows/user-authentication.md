---
service: "checkout-flow-analyzer"
title: "User Authentication"
generated: "2026-03-03"
type: flow
flow_name: "user-authentication"
flow_type: synchronous
trigger: "User navigates to any protected route without a valid NextAuth session"
participants:
  - "webUiCheFloAna"
  - "checkoutFlowAnalyzer_authMiddleware"
  - "oktaIdentityCloud"
architecture_ref: "dynamic-continuumSystem-authenticationFlow"
---

# User Authentication

## Summary

When a checkout engineer navigates to any page other than `/login` or `/api/auth/*`, the NextAuth middleware inspects the request for a valid JWT session cookie. If none is found, the user is redirected to the Okta sign-in page. After successful Okta authentication, an OIDC token is returned to the application, validated, and converted into a NextAuth session cookie that grants access to all protected pages and APIs.

## Trigger

- **Type**: user-action
- **Source**: Browser navigation to any protected route (e.g., `/`, `/sessions`, `/top-stats`, or any `/api/*` endpoint other than `/api/auth`)
- **Frequency**: Once per session (or on session expiry at 3600 seconds / 1 hour)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web UI | Initiates the request; receives the redirect; completes the callback | `webUiCheFloAna` |
| Auth and Security Middleware | Validates the JWT on every request; issues the login redirect; applies security headers | `checkoutFlowAnalyzer_authMiddleware` |
| Okta Identity Cloud | Hosts the sign-in UI; issues the OIDC token after credential verification | `oktaIdentityCloud` (stub) |

## Steps

1. **Intercepts request**: The Next.js middleware runs on every request matching `/((?!_next/static|_next/image|favicon.ico).*)`.
   - From: `webUiCheFloAna` (browser)
   - To: `checkoutFlowAnalyzer_authMiddleware`
   - Protocol: HTTP (same-origin)

2. **Checks for valid JWT**: Middleware calls `getToken({ req: request })` from `next-auth/jwt`. If no token exists, the request is not authenticated.
   - From: `checkoutFlowAnalyzer_authMiddleware`
   - To: NextAuth JWT store (cookie on the request)
   - Protocol: In-process

3. **Redirects to login**: Middleware constructs a redirect URL: `/login?callbackUrl=<encoded-original-url>` and returns a `302` response to the browser.
   - From: `checkoutFlowAnalyzer_authMiddleware`
   - To: `webUiCheFloAna` (browser)
   - Protocol: HTTP 302 redirect

4. **Renders sign-in page**: The `/login` page is served. The user initiates sign-in, which triggers NextAuth to redirect to Okta's OIDC authorization endpoint.
   - From: `webUiCheFloAna`
   - To: `oktaIdentityCloud`
   - Protocol: HTTPS / OIDC Authorization Code redirect

5. **User authenticates with Okta**: The user enters credentials on the Okta-hosted login form. Okta validates them and issues an authorization code.
   - From: User (browser)
   - To: `oktaIdentityCloud`
   - Protocol: HTTPS

6. **OIDC callback returns token**: Okta redirects the browser to `/api/auth/callback/okta` with the authorization code. NextAuth exchanges it for an ID token and creates a signed session JWT stored in a cookie.
   - From: `oktaIdentityCloud`
   - To: `checkoutFlowAnalyzer_authMiddleware` (via `apiRoutesCheFloAna`)
   - Protocol: HTTPS / OIDC

7. **Redirects to original destination**: NextAuth redirects the browser to the original `callbackUrl` (if same-origin) or to the application root.
   - From: `checkoutFlowAnalyzer_authMiddleware`
   - To: `webUiCheFloAna`
   - Protocol: HTTP 302 redirect

8. **Applies security headers**: On all subsequent authenticated requests, middleware applies `Content-Security-Policy`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, and other headers defined in `src/utils/security.ts`.
   - From: `checkoutFlowAnalyzer_authMiddleware`
   - To: `webUiCheFloAna`
   - Protocol: HTTP response headers

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Okta is unreachable | NextAuth surfaces an auth error on the `/login` page | User sees an error message; cannot sign in |
| Invalid Okta credentials | Okta returns an error to the OIDC callback | NextAuth displays a sign-in error |
| Expired session (> 3600s) | `getToken()` returns null; middleware re-issues the login redirect | User is sent back to `/login` with original URL preserved in `callbackUrl` |
| Authenticated user visits `/login` | Middleware detects valid token and redirects to `/` | User bypasses the login page |
| Dev mode active (`NEXT_PUBLIC_AUTH_DEV_MODE=true`) | `CredentialsProvider` accepts any non-empty username/password | No Okta dependency; useful for local development |

## Sequence Diagram

```
Browser            Middleware          NextAuth          Okta
  |                    |                  |               |
  |--GET /sessions---> |                  |               |
  |                    |--getToken()----> |               |
  |                    |<--null-----------|               |
  |<--302 /login?cb=.--|                  |               |
  |--GET /login------> |                  |               |
  |<--200 login page---|                  |               |
  |--POST sign-in----> |                  |               |
  |                    |--redirect to Okta OIDC auth----> |
  |<--redirect to Okta sign-in page-----------------------|
  |--credentials------------------------------------>     |
  |<--302 /api/auth/callback/okta?code=...---------       |
  |--GET /api/auth/callback/okta?code=.---------> |       |
  |                    |              exchange code------> |
  |                    |              <--id_token---------|
  |                    |<--session JWT--|                  |
  |<--302 /sessions (set-cookie)---|                       |
  |--GET /sessions (with cookie)-> |                       |
  |                    |--getToken()----> |                |
  |                    |<--valid token----|                |
  |<--200 /sessions + security headers--|                  |
```

## Related

- Architecture dynamic view: `dynamic-continuumSystem-authenticationFlow`
- Related flows: [Time Window Selection](time-window-selection.md), [Session List Loading](session-list-loading.md)
