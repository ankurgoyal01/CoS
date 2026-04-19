---
service: "merchant-center-web"
title: "Merchant Login"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "merchant-login"
flow_type: synchronous
trigger: "User navigates to /login or is redirected from an authenticated route"
participants:
  - "merchantCenterWebSPA"
  - "continuumDoormanSSO"
  - "continuumUmapi"
architecture_ref: "dynamic-continuum-merchant-login"
---

# Merchant Login

## Summary

The merchant login flow authenticates merchants to the Merchant Center Web portal using Doorman SSO. When an unauthenticated user visits any protected route or navigates to `/login`, the SPA redirects them to the Doorman authorization endpoint. On successful authentication, Doorman redirects back to the SPA with a session token, which the application stores in browser session storage and uses for all subsequent API calls.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `/login`, or client-side route guard detects unauthenticated session on any `/account/*`, `/onboarding/*`, `/messages`, or `/` route.
- **Frequency**: On-demand (per login session)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates login; submits credentials to Doorman | N/A (human actor) |
| Merchant Center Web SPA | Route guard detects unauthenticated state; redirects to Doorman; handles callback | `merchantCenterWebSPA` |
| Doorman SSO | Authenticates merchant identity; issues session token | `continuumDoormanSSO` |
| UMAPI | Provides merchant profile data post-login | `continuumUmapi` |

## Steps

1. **Route Guard Triggers Redirect**: The SPA route guard detects no valid session in browser storage.
   - From: `merchantCenterWebSPA` (route guard)
   - To: `continuumDoormanSSO`
   - Protocol: OAuth2 redirect (browser redirect to Doorman authorization URL)

2. **Merchant Authenticates with Doorman**: Merchant enters credentials on the Doorman login page. Doorman validates identity.
   - From: Merchant (browser)
   - To: `continuumDoormanSSO`
   - Protocol: HTTPS form submission

3. **Doorman Issues Session Token and Redirects**: On success, Doorman redirects the browser back to the SPA callback URL with an authorization code or session token.
   - From: `continuumDoormanSSO`
   - To: `merchantCenterWebSPA`
   - Protocol: OAuth2 authorization code redirect

4. **SPA Stores Session Token**: The SPA receives the token via the callback URL, validates it, and stores it in browser session storage.
   - From: `merchantCenterWebSPA` (callback handler)
   - To: Browser session storage
   - Protocol: In-browser (direct)

5. **SPA Fetches Merchant Profile**: The SPA calls UMAPI to retrieve the authenticated merchant's profile and permissions.
   - From: `merchantCenterWebSPA`
   - To: `continuumUmapi`
   - Protocol: REST / HTTPS (proxied, Bearer token)

6. **Merchant Lands on Dashboard**: The SPA navigates to `/` and renders the merchant dashboard with profile data.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Doorman SSO unavailable | Redirect fails or times out | Merchant sees error page on `/login`; cannot proceed |
| Invalid / expired session token | Route guard clears storage and re-triggers redirect | Merchant redirected back to Doorman login |
| UMAPI profile fetch fails | react-query error state on dashboard | Dashboard renders with error banner; retry possible |
| Merchant account not authorized | Doorman returns authorization error | Error message displayed on `/login` |

## Sequence Diagram

```
Merchant -> merchantCenterWebSPA: Navigate to protected route
merchantCenterWebSPA -> continuumDoormanSSO: Redirect to authorization URL (OAuth2)
continuumDoormanSSO -> Merchant: Present login form
Merchant -> continuumDoormanSSO: Submit credentials
continuumDoormanSSO -> merchantCenterWebSPA: Redirect with session token (callback)
merchantCenterWebSPA -> merchantCenterWebSPA: Store token in session storage
merchantCenterWebSPA -> continuumUmapi: GET /merchant/profile (Bearer token)
continuumUmapi --> merchantCenterWebSPA: Merchant profile JSON
merchantCenterWebSPA -> Merchant: Render dashboard at /
```

## Related

- Architecture dynamic view: `dynamic-continuum-merchant-login`
- Related flows: [Merchant Onboarding](merchant-onboarding.md), [2FA Enrollment](2fa-enrollment.md)
