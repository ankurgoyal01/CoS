---
service: "pricing-control-center-ui"
title: "Authentication and Token Handoff"
generated: "2026-03-03"
type: flow
flow_name: "authentication-token-handoff"
flow_type: synchronous
trigger: "User requests any page route without a valid authn_token cookie"
participants:
  - "continuumPricingControlCenterUi"
  - "doormanAuth_2e7c6d5b"
architecture_ref: "dynamic-pccUiAuthAndSearchFlow"
---

# Authentication and Token Handoff

## Summary

When an internal operator accesses the Pricing Control Center without a valid session, the UI redirects them to Doorman SSO for authentication. Doorman authenticates the user and redirects back to `/post-user-auth-token` with a signed token. The UI writes the token as a cookie (6-hour TTL) and redirects to the home page. All subsequent page requests include this cookie, which is then forwarded as the `authn-token` header in every downstream call to `pricing-control-center-jtier`.

## Trigger

- **Type**: user-action
- **Source**: Browser request to any guarded route (e.g., `/`, `/search-box-jtier`, `/manual-sale-new`) with no `authn_token` cookie, or direct browser navigation to `/doorman`
- **Frequency**: Per session (once per 6-hour window); on every new login or session expiry

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (operator) | Initiates requests; stores `authn_token` cookie | N/A |
| Pricing Control Center UI | Guards routes; initiates and completes Doorman redirect; writes cookie | `continuumPricingControlCenterUi` |
| Doorman SSO | Authenticates user; issues signed token | `doormanAuth_2e7c6d5b` |

## Steps

1. **Route guard checks token**: Browser requests a guarded page route (e.g., `GET /`).
   - From: Browser
   - To: `continuumPricingControlCenterUi` (`routeAndPageHandlers`)
   - Protocol: HTTPS

2. **Detect missing token, redirect to Doorman gateway**: `routeAndPageHandlers` detects that `authn_token` is absent or empty; calls `authRedirectGateway` which returns `redirect("/doorman")`.
   - From: `routeAndPageHandlers`
   - To: `authRedirectGateway`
   - Protocol: Direct (in-process)

3. **Issue Doorman redirect**: `GET /doorman` handler constructs the environment-specific Doorman URL with `destinationPath=/post-user-auth-token` and returns an HTTP 302 redirect.
   - From: `continuumPricingControlCenterUi`
   - To: Browser
   - Protocol: HTTP 302

4. **Browser follows redirect to Doorman**: Browser navigates to Doorman SSO (`doorman-na.groupondev.com` in production).
   - From: Browser
   - To: `doormanAuth_2e7c6d5b`
   - Protocol: HTTPS

5. **Doorman authenticates user**: Doorman performs SSO authentication (internal Okta flow), then redirects the browser back to the service with a signed token appended to the `destinationPath`.
   - From: `doormanAuth_2e7c6d5b`
   - To: Browser
   - Protocol: HTTPS redirect

6. **Receive token callback**: Browser posts to `POST /post-user-auth-token` with the token in the request body.
   - From: Browser
   - To: `continuumPricingControlCenterUi` (`authRedirectGateway` — `modules/auth/actions.js`)
   - Protocol: HTTPS/POST (CSRF exempt)

7. **Write authn_token cookie and redirect home**: `authRedirectGateway` writes the `authn_token` cookie with `maxAge: 6*60*60*1000` (6 hours) and returns `redirect(routeUrl('homeMain'))`.
   - From: `authRedirectGateway`
   - To: Browser
   - Protocol: HTTP 302 + Set-Cookie

8. **Home page renders**: Browser follows redirect to `GET /`; the guarded home route now finds a valid `authn_token` cookie and serves the Preact home page.
   - From: Browser
   - To: `continuumPricingControlCenterUi`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `DEPLOY_ENV` not `staging` or `production` | `/doorman` handler returns early (no redirect) | Redirect does not fire in development/test environments |
| Token callback fails (bad token) | `POST /post-user-auth-token` returns `redirect("/error")` with HTTP 302 | User sees the error page |
| Doorman outage | User is stuck at the Doorman redirect step | Existing sessions (valid cookie) continue for up to 6 hours; new logins are blocked |

## Sequence Diagram

```
Browser -> PricingControlCenterUI: GET /
PricingControlCenterUI -> PricingControlCenterUI: check authn_token cookie (missing)
PricingControlCenterUI --> Browser: 302 redirect /doorman
Browser -> PricingControlCenterUI: GET /doorman
PricingControlCenterUI --> Browser: 302 redirect doorman-na.groupondev.com/?destinationPath=/post-user-auth-token
Browser -> DoormanSSO: GET /authentication/initiation/dynamic-pricing-control-center
DoormanSSO --> Browser: 302 redirect /post-user-auth-token?token=<signed_token>
Browser -> PricingControlCenterUI: POST /post-user-auth-token {token: <signed_token>}
PricingControlCenterUI -> PricingControlCenterUI: cookie.set('authn_token', token, maxAge: 6h)
PricingControlCenterUI --> Browser: 302 redirect / + Set-Cookie: authn_token=<token>
Browser -> PricingControlCenterUI: GET /
PricingControlCenterUI --> Browser: 200 Home page HTML
```

## Related

- Architecture dynamic view: `dynamic-pccUiAuthAndSearchFlow` (disabled pending external stub federation)
- Related flows: [Product Search](product-search.md), [Sale Lifecycle Management](sale-lifecycle-management.md)
