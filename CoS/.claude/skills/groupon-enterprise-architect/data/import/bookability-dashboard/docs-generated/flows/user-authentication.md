---
service: "bookability-dashboard"
title: "User Authentication"
generated: "2026-03-03"
type: flow
flow_name: "user-authentication"
flow_type: synchronous
trigger: "User navigates to the dashboard URL in a browser"
participants:
  - "continuumBookabilityDashboardWeb"
  - "bookDash_authWorkflow"
  - "continuumUniversalMerchantApi"
architecture_ref: "dynamic-bookability-dashboard-data-fetch"
---

# User Authentication

## Summary

When a user accesses the Bookability Dashboard, the application checks whether they hold a valid internal session. If not, it redirects them through the internal Doorman/OKTA OAuth flow. Once authenticated, the dashboard fetches the user's identity and role from the Universal Merchant API and gates access accordingly. Localhost users bypass authentication entirely for local development.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `https://www.groupon.com/bookability/dashboard/` (or staging equivalent)
- **Frequency**: Per browser session (cookie-based sessions persist until expiry or logout)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dashboard App Shell | Bootstraps the application, renders `AuthWrapper` | `bookDash_appShell` |
| Internal Auth Workflow | Determines auth state and handles login/logout | `bookDash_authWorkflow` |
| Universal Merchant API | Provides user identity and role via `/v2/merchant_oauth/internal/me` | `continuumUniversalMerchantApi` |
| Doorman | External auth gateway (OKTA-backed); redirected to by `AuthWrapper` when session is absent | External (referenced via `DOORMAN_URL`) |

## Steps

1. **Bootstrap protection check**: The `App` component reads `window._env_.NAME` and `window._env_.DOORMAN_URL`. If the environment is `production` or `staging` and `DOORMAN_URL` is absent, the app renders a black screen and stops.
   - From: `bookDash_appShell`
   - To: Browser DOM
   - Protocol: In-process

2. **Render AuthWrapper**: `AuthWrapper` mounts and calls `fetchUser()` via `AppContext`. User state is initially `undefined` (loading).
   - From: `bookDash_authWorkflow`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST (`GET /v2/merchant_oauth/internal/me?clientId=tpis`)

3. **Receive identity response**: `continuumUniversalMerchantApi` returns `{ user: { id, userRole, email } }`. The response is mapped to `AppUser` and stored in context.
   - From: `continuumUniversalMerchantApi`
   - To: `bookDash_authWorkflow`
   - Protocol: REST (JSON response)

4. **Handle unauthenticated state**: If the identity call returns a non-2xx response (e.g., 401), `user` is set to `null`. `AuthWrapper` detects `null` and renders `LoginInternal`, which redirects the user to `DOORMAN_URL` for OKTA login.
   - From: `bookDash_authWorkflow`
   - To: Doorman (browser redirect)
   - Protocol: HTTPS redirect (OAuth2)

5. **Return from Doorman**: After successful OKTA authentication, Doorman sets a session cookie and redirects the user back to the dashboard. `AuthWrapper` retries `fetchUser()` and receives a valid user identity.
   - From: Doorman
   - To: `bookDash_authWorkflow`
   - Protocol: Browser redirect + cookie

6. **Role check and render**: If `user.userRole` does not meet required access level, `AccessDenied` is rendered. Otherwise, the `MainApp` component is mounted and data loading begins.
   - From: `bookDash_authWorkflow`
   - To: `bookDash_appShell`
   - Protocol: In-process (React context)

7. **Logout**: Calling `refresh(true)` clears `user` to `null`, removes the `authToken` cookie (`document.cookie = "authToken=; expires=..."`), and re-triggers the login flow.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Identity API returns 401 | `user` set to `null`; `LoginInternal` rendered; redirect to Doorman | User prompted to log in |
| Identity API returns 503 | `isDown` set to `true` in context | Service-unavailable state displayed |
| Doorman unavailable | Browser cannot complete OAuth redirect | User sees browser network error |
| `DOORMAN_URL` absent in protected env | App renders black screen immediately | Access blocked entirely |
| Localhost access | Authentication bypassed; `user` set to `{ id: 'localhost-user', userRole: 'ADMIN' }` | Full access granted for local development |

## Sequence Diagram

```
Browser -> AppShell: Load dashboard URL
AppShell -> AuthWrapper: Mount with DOORMAN_URL check
AuthWrapper -> UniversalMerchantApi: GET /v2/merchant_oauth/internal/me
UniversalMerchantApi --> AuthWrapper: { user: { id, userRole, email } }
AuthWrapper -> AppShell: Set user context, render MainApp
--- (if unauthenticated) ---
UniversalMerchantApi --> AuthWrapper: 401 Unauthorized
AuthWrapper -> Doorman: Browser redirect to DOORMAN_URL
Doorman -> Browser: OKTA login page
Browser -> Doorman: Credentials submitted
Doorman --> Browser: Session cookie + redirect to dashboard
Browser -> AuthWrapper: Reload with valid session cookie
AuthWrapper -> UniversalMerchantApi: GET /v2/merchant_oauth/internal/me (retry)
UniversalMerchantApi --> AuthWrapper: { user: { id, userRole, email } }
AuthWrapper -> AppShell: Set user context, render MainApp
```

## Related

- Architecture dynamic view: `dynamic-bookability-dashboard-data-fetch`
- Related flows: [Dashboard Data Load](dashboard-data-load.md)
